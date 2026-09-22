# Backup Chute / Dù cứu viện - thêm 1 lính vào hàng chờ thả (Update_Feature.md 1.3).
# Hình ảnh: backup_chute_spritesheet.svg -> backup_chute_frames.tres (animation "bob") trong backup_chute.tscn.
# Việc +1 lính do GameLogicController xử lý qua signal item_collected (_on_item_collected).
class_name BackupChuteItem
extends Item
