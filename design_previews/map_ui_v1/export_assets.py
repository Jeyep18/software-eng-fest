from pathlib import Path
from PIL import Image


SOURCE = Path(__file__).parent
DEST = SOURCE.parents[1] / "game" / "assets" / "map_ui"
DEST.mkdir(parents=True, exist_ok=True)


def export_cutout(name: str, canvas: int, inset: int) -> None:
	image = Image.open(SOURCE / name).convert("RGBA")
	alpha = image.getchannel("A")
	bounds = alpha.point(lambda value: 255 if value > 16 else 0).getbbox()
	if bounds is None:
		raise ValueError(f"Empty cutout: {name}")
	image = image.crop(bounds)
	image.thumbnail((canvas - inset * 2, canvas - inset * 2), Image.Resampling.LANCZOS)
	output = Image.new("RGBA", (canvas, canvas))
	output.alpha_composite(image, ((canvas - image.width) // 2, (canvas - image.height) // 2))
	output.save(DEST / name)


Image.open(SOURCE / "map_base.png").save(DEST / "map_base.png")
Image.open(SOURCE / "storm_front_clouds.png").save(DEST / "storm_front_clouds.png")
for name in ("icon_home.png", "icon_ate_linda.png", "icon_hardware.png", "icon_botika.png", "icon_palengke.png"):
	export_cutout(name, 256, 18)
for name in ("storm_wash.png", "storm_wind.png", "storm_eye.png"):
	export_cutout(name, 512, 14)
