# Đồng xu vàng - currency cho progression/shop (Update_Feature.md 1.1).
# Hình ảnh: coin_spritesheet.svg -> coin_frames.tres (animation "spin") khai báo trong coin.tscn.
# Việc cộng coin vào GameState do GameLogicController xử lý qua signal item_collected.
class_name CoinItem
extends Item
