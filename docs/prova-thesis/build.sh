#!/bin/bash
# Prova Thesis Build Script
# This script compiles the LaTeX thesis and creates versioned PDF backups.

# Exit on error
set -e

echo "Compiling Prova Thesis..."

# Run pdflatex
pdflatex -interaction=nonstopmode main.tex
biber main || true
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex

# Get current timestamp for versioning
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
VERSION_DIR="versions"
DOCX_BUILT=0

# Create versions directory if it doesn't exist
mkdir -p "$VERSION_DIR"

# Copy the compiled PDF to the versions folder
cp main.pdf "$VERSION_DIR/prova_thesis_v${TIMESTAMP}.pdf"

if command -v pandoc >/dev/null 2>&1; then
	echo "Generating DOCX (Pandoc)..."
	if command -v python3 >/dev/null 2>&1; then
		PYTHON_BIN=python3
	elif command -v python >/dev/null 2>&1; then
		PYTHON_BIN=python
	else
		echo "Warning: neither python3 nor python was found. Skipping DOCX output."
		PYTHON_BIN=""
	fi
fi

if [[ -n "${PYTHON_BIN:-}" ]]; then
	PANDOC_TEX=$(mktemp)
	"$PYTHON_BIN" - "$PANDOC_TEX" <<'PY'
import re
import sys
from pathlib import Path

src = Path("main.tex").read_text(encoding="utf-8").splitlines()
out = []
inmacro = False
depth = 0

def brace_delta(line: str) -> int:
	return line.count("{") - line.count("}")

for line in src:
	if not inmacro and re.match(r"^\\newcommand\{\\frontmatterchapter\}", line):
		inmacro = True
		depth = brace_delta(line)
		continue
	if inmacro:
		depth += brace_delta(line)
		if depth <= 0:
			inmacro = False
		continue
	m = re.match(r"^\\frontmatterchapter\{([^}]*)\}", line)
	if m:
		title = m.group(1)
		out.append(f"\\chapter*{{{title}}}")
		out.append(f"\\addcontentsline{{toc}}{{chapter}}{{{title}}}")
		continue
	out.append(line)

Path(sys.argv[1]).write_text("\n".join(out) + "\n", encoding="utf-8")
PY
	PANDOC_ARGS=(
		"$PANDOC_TEX"
		--from=latex
		--to=docx
		--output=main.docx
		--resource-path=.:figures:chapters
		--toc
		--toc-depth=3
		--number-sections
		--top-level-division=chapter
		--bibliography=references.bib
	)
	if [[ -f reference.docx ]]; then
		PANDOC_ARGS+=(--reference-doc=reference.docx)
	else
		echo "Warning: reference.docx not found; using Pandoc defaults."
	fi
	if pandoc --help 2>/dev/null | grep -q -- "--citeproc"; then
		PANDOC_ARGS+=(--citeproc)
	elif command -v pandoc-citeproc >/dev/null 2>&1; then
		PANDOC_ARGS+=(--filter pandoc-citeproc)
	else
		echo "Warning: citeproc not available; bibliography may be missing in DOCX."
	fi
	if pandoc "${PANDOC_ARGS[@]}"; then
		"$PYTHON_BIN" <<'PY'
import re
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

NS = {
	"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
}
W = "{" + NS["w"] + "}"
ET.register_namespace("w", NS["w"])

def read_group(text, start):
	while start < len(text) and text[start].isspace():
		start += 1
	if start >= len(text) or text[start] != "{":
		return "", start
	depth = 0
	out = []
	i = start
	while i < len(text):
		ch = text[i]
		if ch == "{":
			depth += 1
			if depth > 1:
				out.append(ch)
		elif ch == "}":
			depth -= 1
			if depth == 0:
				return "".join(out), i + 1
			out.append(ch)
		else:
			out.append(ch)
		i += 1
	return "".join(out), i

def clean_title(raw):
	match = re.match(r"\\numberline\s*\{([^}]*)\}(.*)", raw)
	if match:
		raw = f"{match.group(1)} {match.group(2)}"
	raw = re.sub(r"\\[a-zA-Z]+\s*\{([^{}]*)\}", r"\1", raw)
	raw = raw.replace("\\&", "&").replace("~", " ")
	raw = raw.replace("{", "").replace("}", "")
	return " ".join(raw.split())

def toc_entries():
	levels = {"chapter": 0, "section": 1, "subsection": 2}
	entries = []
	for line in Path("main.toc").read_text(encoding="utf-8").splitlines():
		if not line.startswith(r"\contentsline"):
			continue
		pos = len(r"\contentsline")
		kind, pos = read_group(line, pos)
		title, pos = read_group(line, pos)
		page, _ = read_group(line, pos)
		if kind in levels:
				entries.append((levels[kind], clean_title(title), page.strip()))
	return entries

def paragraph(text=None, style=None, level=0, page=None, align=None, size=None, bold=False, page_before=False, spacing_before=None, spacing_after=None):
	p = ET.Element(W + "p")
	ppr = ET.SubElement(p, W + "pPr")
	if style:
		pstyle = ET.SubElement(ppr, W + "pStyle")
		pstyle.set(W + "val", style)
	if page_before:
		ET.SubElement(ppr, W + "pageBreakBefore")
	if align:
		jc = ET.SubElement(ppr, W + "jc")
		jc.set(W + "val", align)
	if spacing_before is not None or spacing_after is not None:
		spacing = ET.SubElement(ppr, W + "spacing")
		if spacing_before is not None:
			spacing.set(W + "before", str(spacing_before))
		if spacing_after is not None:
			spacing.set(W + "after", str(spacing_after))
	if page is not None:
		ind = ET.SubElement(ppr, W + "ind")
		ind.set(W + "left", str(level * 360))
		tabs = ET.SubElement(ppr, W + "tabs")
		tab = ET.SubElement(tabs, W + "tab")
		tab.set(W + "val", "right")
		tab.set(W + "leader", "dot")
		tab.set(W + "pos", "9360")
	r = ET.SubElement(p, W + "r")
	if size or bold:
		rpr = ET.SubElement(r, W + "rPr")
		if bold:
			ET.SubElement(rpr, W + "b")
		if size:
			sz = ET.SubElement(rpr, W + "sz")
			sz.set(W + "val", str(size))
			szcs = ET.SubElement(rpr, W + "szCs")
			szcs.set(W + "val", str(size))
	t = ET.SubElement(r, W + "t")
	t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
	t.text = text or ""
	if page is not None:
		ET.SubElement(p, W + "r").append(ET.Element(W + "tab"))
		r_page = ET.SubElement(p, W + "r")
		t_page = ET.SubElement(r_page, W + "t")
		t_page.text = page
	return p

def page_break():
	p = ET.Element(W + "p")
	r = ET.SubElement(p, W + "r")
	br = ET.SubElement(r, W + "br")
	br.set(W + "type", "page")
	return p

def paragraph_style(p):
	style = p.find(f"./{W}pPr/{W}pStyle")
	return style.get(W + "val") if style is not None else ""

def paragraph_text(p):
	return "".join(node.text or "" for node in p.findall(f".//{W}t")).strip()

def ensure_child(parent, tag):
	child = parent.find(tag)
	if child is None:
		child = ET.SubElement(parent, tag)
	return child

def set_or_add(parent, tag, **attrs):
	child = parent.find(tag)
	if child is None:
		child = ET.SubElement(parent, tag)
	for key, value in attrs.items():
		child.set(W + key, str(value))
	return child

def apply_table_formatting(body):
	for tbl in body.findall(f".//{W}tbl"):
		tblpr = ensure_child(tbl, W + "tblPr")
		set_or_add(tblpr, W + "tblW", type="pct", w="5000")
		set_or_add(tblpr, W + "jc", val="center")
		set_or_add(tblpr, W + "tblLayout", type="autofit")

		borders = ensure_child(tblpr, W + "tblBorders")
		for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
			set_or_add(borders, W + side, val="single", sz="4", space="0", color="BFBFBF")

		margins = ensure_child(tblpr, W + "tblCellMar")
		for side in ("top", "left", "bottom", "right"):
			set_or_add(margins, W + side, w="90", type="dxa")

		for tc in tbl.findall(f".//{W}tc"):
			tcpr = ensure_child(tc, W + "tcPr")
			set_or_add(tcpr, W + "tcW", type="auto", w="0")
			for p in tc.findall(W + "p"):
				ppr = ensure_child(p, W + "pPr")
				set_or_add(ppr, W + "spacing", before="0", after="80")

def style_by_id(styles_root, style_id):
	for style in styles_root.findall(W + "style"):
		if style.get(W + "styleId") == style_id:
			return style
	return None

def apply_style_spacing(styles_root):
	for style_id, before, after in (
		("Heading1", "360", "180"),
		("Heading2", "300", "120"),
		("Heading3", "240", "100"),
		("BodyText", "0", "160"),
		("FirstParagraph", "0", "160"),
	):
		style = style_by_id(styles_root, style_id)
		if style is None:
			continue
		ppr = ensure_child(style, W + "pPr")
		set_or_add(ppr, W + "spacing", before=before, after=after)

def chapter_title_pages(body, entries):
	chapter_numbers = {}
	for level, title, _page in entries:
		if level != 0:
			continue
		match = re.match(r"^(\d+)\s+(.+)$", title)
		if match:
			chapter_numbers[match.group(2)] = match.group(1)

	if not chapter_numbers:
		return

	new_children = []
	for child in list(body):
		if child.tag == W + "p" and paragraph_style(child) == "Heading1":
			title = paragraph_text(child)
			number = chapter_numbers.get(title)
			if number:
				new_children.append(paragraph(f"Chapter {number}", "Heading1", align="center", size=34, bold=True, page_before=True, spacing_before=4200, spacing_after=240))
				new_children.append(paragraph(title, "Heading1", align="center", size=44, bold=True, spacing_before=0, spacing_after=0))
				new_children.append(page_break())
				continue
		new_children.append(child)

	body[:] = new_children

docx = Path("main.docx")
with zipfile.ZipFile(docx, "r") as zin:
	files = {item.filename: zin.read(item.filename) for item in zin.infolist()}

root = ET.fromstring(files["word/document.xml"])
body = root.find(W + "body")
entries = toc_entries()

# Remove Pandoc's dynamic TOC field because many Word viewers show it blank until fields are updated.
for child in list(body):
	if child.tag == W + "sdt":
		body.remove(child)

insert_at = None
for idx, child in enumerate(list(body)):
	if child.tag != W + "p":
		continue
	style = child.find(f"./{W}pPr/{W}pStyle")
	text = "".join(node.text or "" for node in child.findall(f".//{W}t"))
	if style is not None and style.get(W + "val") == "Heading1" and text.strip() == "Introduction":
		insert_at = idx
		break

if insert_at is None:
	insert_at = 0

toc_nodes = [paragraph("Table of Contents", "TOCHeading")]
for level, title, page in entries:
	toc_nodes.append(paragraph(title, "BodyText", level=level, page=page))
toc_nodes.append(page_break())

for offset, node in enumerate(toc_nodes):
	body.insert(insert_at + offset, node)

chapter_title_pages(body, entries)
apply_table_formatting(body)

files["word/document.xml"] = ET.tostring(root, encoding="utf-8", xml_declaration=True)

styles_root = ET.fromstring(files["word/styles.xml"])
apply_style_spacing(styles_root)
files["word/styles.xml"] = ET.tostring(styles_root, encoding="utf-8", xml_declaration=True)

with tempfile.NamedTemporaryFile(delete=False, suffix=".docx", dir=docx.parent) as tmp:
	tmp_path = Path(tmp.name)

with zipfile.ZipFile(tmp_path, "w", zipfile.ZIP_DEFLATED) as zout:
	for name, data in files.items():
		zout.writestr(name, data)

tmp_path.replace(docx)
PY
		cp main.docx "$VERSION_DIR/prova_thesis_v${TIMESTAMP}.docx"
		DOCX_BUILT=1
	else
		echo "Warning: DOCX generation failed."
	fi
	rm -f "$PANDOC_TEX"
else
	if ! command -v pandoc >/dev/null 2>&1; then
		echo "Warning: pandoc not found. Skipping DOCX output."
	fi
fi

echo "================================================="
echo "Build Successful!"
echo "Current PDF: main.pdf"
if [[ "$DOCX_BUILT" == "1" ]]; then
	echo "Current DOCX: main.docx"
	echo "Versioned DOCX: $VERSION_DIR/prova_thesis_v${TIMESTAMP}.docx"
fi
echo "Versioned Backup: $VERSION_DIR/prova_thesis_v${TIMESTAMP}.pdf"
echo "================================================="
