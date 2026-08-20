# VERT

A local file converter for the Omarchy Quattro bar. Pick a file, choose a
target format, and it's converted on-device into `~/Downloads` — no cloud.

Built on the same conversion engines as [VERT](https://github.com/VERT-sh/vert):

| Family       | Engine       |
|--------------|--------------|
| Images       | ImageMagick  |
| Audio, video | FFmpeg       |
| Documents    | Pandoc       |

## Install

```sh
omarchy plugin add https://github.com/TMartinPPC/omarchy-vert.git --enable
```

## Usage

Click the VERT icon in the bar to open the panel:

1. Press **Choose file…** to pick a file (the panel hides while the chooser is
   open, then reopens with the file loaded).
2. Choose a target format from the dropdown (the options follow the file type).
3. Press **Convert**. The result lands in `~/Downloads/<name>.<ext>`, with a
   numeric suffix when a file of that name already exists.

Press **Reset** to clear the selection, or **Escape** to close the panel.

## Requirements

Omarchy ships ImageMagick and FFmpeg. Document conversion needs Pandoc, and
Pandoc's PDF output needs a LaTeX engine:

```sh
omarchy pkg add pandoc
# PDF output also needs one of:
omarchy pkg add tectonic   # or: omarchy pkg add texlive
```

## Configure

The output folder defaults to `~/Downloads`. To change it, add an `outputDir`
field to this widget's entry in the `bar.layout` section of
`~/.config/omarchy/shell.json`:

```json
{ "id": "io.github.tmartinppc.vert", "outputDir": "/path/to/folder" }
```

The bar icon can be moved like any widget:

```sh
omarchy bar move io.github.tmartinppc.vert --section right
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
omarchy plugin remove io.github.tmartinppc.vert
```

## License

MIT