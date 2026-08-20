# OmaVERT

A local file converter for the Omarchy Quattro bar. Pick a file, choose a
target format, and it's converted on-device into `~/Downloads` — no cloud.

Inspired by [VERT](https://github.com/VERT-sh/vert) and built on the same
fully-local conversion engines it uses: ImageMagick (images), FFmpeg
(audio/video), and Pandoc (documents). OmaVERT shares no code with VERT.

## Install

```sh
omarchy plugin add https://github.com/TMartinPPC/omarchy-omavert.git --enable
```

## Usage

Click the OmaVERT icon in the bar to open the panel:

1. Press **Choose file…** to pick a file (the panel hides while the chooser is
   open, then reopens with the file loaded).
2. Choose a target format from the dropdown (options follow the file type).
3. Press **Convert**. The result lands in `~/Downloads/<name>.<ext>`, with a
   numeric suffix when a file of that name already exists.

Press **Reset** to clear the selection, or **Escape** to close the panel.

## Dependencies

Each conversion type uses a different engine. Install what you need:

| What you convert   | Engine          | Package(s)      |
|--------------------|-----------------|-----------------|
| **Images**         | ImageMagick     | `imagemagick`   |
| **Audio**          | FFmpeg          | `ffmpeg`        |
| **Video**          | FFmpeg          | `ffmpeg`        |
| **Documents**      | Pandoc          | `pandoc`        |

Omarchy ships `imagemagick` and `ffmpeg` by default. Document conversion is
optional — install Pandoc only if you convert documents:

```sh
omarchy pkg add pandoc
```

### Optional image delegates

A few image formats need an extra ImageMagick delegate. Install only the ones
for the formats you actually use:

| Format                  | Delegate package |
|-------------------------|------------------|
| SVG                     | `librsvg`        |
| HEIC / HEIF / AVIF      | `libheif`        |
| JPEG XL (JXL)           | `libjxl`         |
| PDF (from an image)     | `ghostscript`    |

```sh
omarchy pkg add librsvg libheif libjxl ghostscript
```

### PDF output from documents

Pandoc renders PDF through a LaTeX engine. Install one:

```sh
omarchy pkg add tectonic       # single self-contained binary (recommended)
# or, the full toolchain:
omarchy pkg add texlive-core   # provides pdflatex
```

## Configure

The output folder defaults to `~/Downloads`. To change it, add an `outputDir`
field to this widget's entry in the `bar.layout` section of
`~/.config/omarchy/shell.json`:

```json
{ "id": "io.github.tmartinppc.omavert", "outputDir": "/path/to/folder" }
```

The bar icon can be moved like any widget:

```sh
omarchy bar move io.github.tmartinppc.omavert --section right
```

To float the file-chooser dialog as a centered window instead of a tiled one,
add a Hyprland rule to `~/.config/hypr/hyprland.lua`:

```lua
hl.window_rule({
  float = true,
  center = true,
  match = { class = "^omafiles-picker$" }
})
```

## Remove

```sh
omarchy plugin remove io.github.tmartinppc.omavert
```

## Credits

OmaVERT is inspired by [VERT](https://github.com/VERT-sh/vert), a fully-local
file converter by the VERT project. It uses the same underlying conversion
engines — [ImageMagick](https://imagemagick.org/),
[FFmpeg](https://ffmpeg.org/), and [Pandoc](https://pandoc.org/) — but
includes none of VERT's source code.

## License

MIT