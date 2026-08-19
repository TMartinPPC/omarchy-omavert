// Format catalogue for the VERT bar widget.
//
// VERT (https://github.com/VERT-sh/vert) converts everything on-device with
// three engines: ImageMagick for images, FFmpeg for audio/video, and Pandoc
// for documents. This file mirrors that split so the panel can classify a
// dropped or picked file and offer the right target formats; convert.sh
// performs the actual conversion.
//
//   classify(ext)      -> "image" | "audio" | "video" | "document" | ""
//   engine(category)   -> "magick" | "ffmpeg" | "pandoc" | ""
//   targets(category)  -> [ { value, label }, ... ]
//   categoryLabel(cat) -> "Image" | "Audio" | "Video" | "Document" | ""

var imageExts = ["png", "jpg", "jpeg", "webp", "gif", "bmp", "tif", "tiff",
  "avif", "heic", "heif", "ico", "svg", "jxl"]

var audioExts = ["mp3", "wav", "flac", "ogg", "oga", "m4a", "opus", "aac",
  "aiff", "aif", "wma"]

var videoExts = ["mp4", "webm", "mkv", "mov", "avi", "flv", "wmv", "m4v",
  "ts", "mts", "m2ts", "3gp"]

var documentExts = ["pdf", "doc", "docx", "odt", "rtf", "md", "markdown",
  "txt", "html", "htm", "epub", "tex", "rst"]

var imageTargets = [
  { value: "png",  label: "PNG — image" },
  { value: "jpg",  label: "JPEG — image" },
  { value: "webp", label: "WebP — image" },
  { value: "gif",  label: "GIF — image" },
  { value: "bmp",  label: "BMP — image" },
  { value: "tif",  label: "TIFF — image" },
  { value: "avif", label: "AVIF — image" },
  { value: "heic", label: "HEIC — image" },
  { value: "ico",  label: "ICO — image" },
  { value: "svg",  label: "SVG — image" }
]

var audioTargets = [
  { value: "mp3",  label: "MP3 — audio" },
  { value: "wav",  label: "WAV — audio" },
  { value: "flac", label: "FLAC — audio" },
  { value: "ogg",  label: "Ogg Vorbis — audio" },
  { value: "m4a",  label: "M4A (AAC) — audio" },
  { value: "opus", label: "Opus — audio" },
  { value: "aac",  label: "AAC — audio" }
]

var videoTargets = [
  { value: "mp4",  label: "MP4 — video" },
  { value: "webm", label: "WebM — video" },
  { value: "mkv",  label: "Matroska — video" },
  { value: "mov",  label: "MOV — video" },
  { value: "avi",  label: "AVI — video" },
  { value: "gif",  label: "GIF — animated" },
  { value: "mp3",  label: "MP3 — audio only" },
  { value: "wav",  label: "WAV — audio only" },
  { value: "flac", label: "FLAC — audio only" },
  { value: "ogg",  label: "Ogg Vorbis — audio only" },
  { value: "m4a",  label: "M4A (AAC) — audio only" },
  { value: "opus", label: "Opus — audio only" },
  { value: "aac",  label: "AAC — audio only" }
]

var documentTargets = [
  { value: "docx", label: "DOCX — Word" },
  { value: "odt",  label: "ODT — LibreOffice" },
  { value: "pdf",  label: "PDF" },
  { value: "html", label: "HTML" },
  { value: "epub", label: "EPUB" },
  { value: "md",   label: "Markdown" },
  { value: "txt",  label: "Plain text" },
  { value: "rtf",  label: "RTF" }
]

function classify(ext) {
  var e = String(ext || "").toLowerCase().replace(/^\./, "")
  var i
  for (i = 0; i < imageExts.length; i++)
    if (imageExts[i] === e) return "image"
  for (i = 0; i < audioExts.length; i++)
    if (audioExts[i] === e) return "audio"
  for (i = 0; i < videoExts.length; i++)
    if (videoExts[i] === e) return "video"
  for (i = 0; i < documentExts.length; i++)
    if (documentExts[i] === e) return "document"
  return ""
}

function engine(category) {
  if (category === "image") return "magick"
  if (category === "audio" || category === "video") return "ffmpeg"
  if (category === "document") return "pandoc"
  return ""
}

function targets(category) {
  if (category === "image") return imageTargets
  if (category === "audio") return audioTargets
  if (category === "video") return videoTargets
  if (category === "document") return documentTargets
  return []
}

function categoryLabel(category) {
  if (category === "image") return "Image"
  if (category === "audio") return "Audio"
  if (category === "video") return "Video"
  if (category === "document") return "Document"
  return ""
}