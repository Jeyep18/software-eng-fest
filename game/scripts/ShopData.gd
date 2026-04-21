# ShopData.gd
# A Resource that defines the catalogue for one shop.
# Create one .tres file per shop (ate_linda_shop.tres, pharmacy_shop.tres, etc.)
# and assign it to the ShopTrigger or NPC node in the Inspector.
class_name ShopData
extends Resource

## Human-readable name shown in the ShopUI header.
## e.g. "Ate Linda's Sari-sari" / "Pharmacy / Botika"
@export var shop_name: String = "Shop"

## Optional subtitle shown under the shop name.
## e.g. "Presyo ay medyo mahal ngayon..." for Linda's price-gouging context.
@export_multiline var shop_subtitle: String = ""

## The list of items this shop sells.
@export var items: Array[ShopItem] = []
