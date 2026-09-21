# GAME DESIGN DOCUMENT (GDD)

## 1. Tổng quan (Overview)

| Mục | Nội dung |
|---|---|
| **Tên game (tạm)** | Drop Zone |
| **Thể loại** | Casual / Arcade — Physics-based Guiding Game |
| **Nền tảng** | Android |
| **Đối tượng người chơi** | Casual gamer, chơi ngắn theo phiên (session-based) |
| **Điều khiển chính** | Tilt (nghiêng thiết bị) |
| **Tầm nhìn (Vision)** | Trò chơi thư giãn nhưng đòi hỏi phản xạ và kiểm soát tinh tế, nơi người chơi dùng thao tác nghiêng máy để dẫn dắt nhân vật rơi tự do vượt qua chướng ngại vật và gió, hạ cánh càng gần tâm mục tiêu càng tốt. |

---

## 2. Core Gameplay Loop

1. Hệ thống **tự động thả nhân vật** sau một khoảng thời gian đếm ngược (không cần người chơi bấm thả).
2. Nhân vật rơi tự do từ độ cao quy định, chịu tác động của:
   - Trọng lực (rơi xuống)
   - **Tilt của người chơi** (lực ngang chính, do người chơi điều khiển)
   - **Gió môi trường** (chướng ngại vật, ngoài ý muốn người chơi)
   - Va chạm với vật cản trên đường rơi (máy bay, chim, dây điện, v.v.)
3. Nhân vật chạm đất tại một vị trí → tính điểm dựa trên **khoảng cách tới tâm hồng tâm (bullseye)**.
4. Lặp lại cho đến khi thả hết số lượng nhân vật quy định trong màn.
5. **Tổng điểm** sau khi thả hết nhân vật được so với **ngưỡng điểm cần đạt**:
   - Đạt ngưỡng → **Thắng màn**
   - Không đạt → **Thua màn**, chơi lại

---

## 3. Cơ chế điều khiển (Controls)

### 3.1. Tilt Control
- Sử dụng gyroscope/accelerometer của thiết bị, đọc góc nghiêng trái/phải (roll axis).
- Nghiêng phải → toàn bộ nhân vật đang rơi bị đẩy lệch phải; nghiêng trái → ngược lại.
- **Vùng chết (dead zone):** ±3–5 độ quanh vị trí cầm máy tự nhiên, tránh trôi nhân vật ngoài ý muốn.
- **Map phi tuyến tính:** nghiêng nhẹ → lực nhỏ; nghiêng mạnh → lực tăng nhanh hơn, hỗ trợ cả điều chỉnh tinh lẫn phản xạ gấp.
- **Giới hạn góc hiệu lực tối đa:** khoảng 30–40 độ, tránh phải nghiêng máy quá mức.
- **Calibration đầu ván:** giữ yên máy vài giây khi bắt đầu để lấy mốc "0 độ" theo tư thế cầm hiện tại của người chơi (đứng / ngồi / nằm đều dùng được).

### 3.2. Accessibility
- Cân nhắc chế độ điều khiển thay thế (nút bấm trái/phải ảo) cho người chơi không tiện dùng tilt (đang di chuyển, không gian hẹp, v.v.).

---

## 4. Hệ thống Vật lý (Physics)

Lực ngang tổng tác động lên nhân vật mỗi frame:

```
Lực ngang tổng = Lực_tilt (người chơi điều khiển)
				+ Lực_gió_môi_trường (chướng ngại vật)
				+ Quán tính hiện tại (velocity trước đó, có damping)
```

- **Quán tính:** lực không đổi hướng vận tốc ngay lập tức, tạo cảm giác "trôi" thực tế.
- **Giới hạn tốc độ ngang tối đa:** tránh mất kiểm soát hoàn toàn.
- **Độ nhạy tăng theo độ cao giảm dần:** càng gần đất, phản ứng với lực tilt/gió càng nhanh hơn, tạo khoảnh khắc "chỉnh gấp" gay cấn ở cuối mỗi lượt rơi.

---

## 5. Hệ thống Gió (Wind — Obstacle)

Gió đóng vai trò **chướng ngại vật ngoài ý muốn**, buộc người chơi phải liên tục bù trừ bằng tilt.

| Loại gió | Mô tả | Tín hiệu cảnh báo |
|---|---|---|
| **Wind Zone** | Vùng không khí cố định gây lực đẩy ngang liên tục khi nhân vật đi qua | Hiệu ứng hạt bụi/đường kẻ chuyển động ngang trong vùng |
| **Gust (gió giật)** | Đẩy mạnh đột ngột trong thời gian ngắn | Icon mũi tên nhấp nháy / rung nhẹ mép màn hình trước 0.5–1s |
| **Turbulence (gió xoáy)** | Giảm hoặc đảo ngược tạm thời hiệu lực tilt của người chơi | Dùng tiết chế, chỉ ở level khó cao |
| **Luồng gió theo tầng độ cao** | Cường độ gió thay đổi theo độ cao rơi | Tạo nhịp độ khó tăng dần trong 1 lượt rơi |

**Feedback trực quan:** dù/quần áo/tóc nhân vật bay theo hướng gió hiện tại, giúp người chơi "đọc" gió mà không cần số liệu.

---

## 6. Chướng ngại vật (Obstacles)

| Nhóm | Ví dụ | Hiệu ứng khi va chạm |
|---|---|---|
| Trên không (di chuyển) | Máy bay, chim, đàn chim, khinh khí cầu, UFO | Thất bại lượt / mất điểm |
| Bắn từ dưới lên | Đạn, pháo hoa | Thất bại lượt |
| Tĩnh / cấu trúc | Dây điện, cần cẩu, tòa nhà, diều có dây | Rối loạn điều khiển tạm thời hoặc thất bại lượt |
| Vùng đặc biệt | Túi khí loãng (rơi nhanh hơn), cột khí nóng (đẩy lên tạm thời) | Thay đổi tốc độ rơi, không giết ngay |

*(Ghi chú: obstacle nên có tín hiệu quan sát được trước khi va chạm, tránh cảm giác "thua vì random".)*

---

## 7. Hệ thống Mục tiêu — Hồng tâm (Target System)

### 7.1. Cấu trúc vòng điểm

| Vùng | Điểm minh họa |
|---|---|
| Tâm (Bullseye) | 100 |
| Vòng 2 | 70 |
| Vòng 3 | 40 |
| Vòng ngoài | 10–20 |
| Ngoài hồng tâm | 0 |

- Điểm mỗi lượt tính theo **vòng chạm đất** (bậc thang, chia nhiều vòng nhỏ để mượt hơn).

### 7.2. Điều kiện thắng/thua
- Tổng điểm sau khi thả hết N nhân vật ≥ **ngưỡng điểm cần đạt** → Thắng.
- Cho phép **bù trừ**: 1–2 lượt đáp kém không làm thua ngay nếu các lượt khác đạt điểm cao.
- Hiển thị ngưỡng điểm mục tiêu rõ ràng trước khi vào màn (progress bar điểm số).

### 7.3. Biến thể nâng cao
- **Nhiều hồng tâm** với kích thước/điểm khác nhau (risk/reward).
- **Hồng tâm di chuyển** ngang chậm hoặc co giãn kích thước theo nhịp thời gian.
- **Hồng tâm đặt lệch theo hướng ngược gió mạnh nhất** để tăng độ khó có chủ đích.

### 7.4. Phản hồi khi đáp đất
- Hiệu ứng particle khác nhau theo vòng điểm (pháo hoa/khói).
- Điểm số nổi (floating score text) tại vị trí đáp.
- Slow-motion nhẹ + camera zoom vào khoảnh khắc chạm đất.

---

## 8. Hệ thống tiến trình & thưởng (Progression & Rewards)

- **Combo:** liên tiếp đáp vào vùng điểm cao → nhân đôi điểm lượt kế tiếp.
- **Perfect clear bonus:** vượt xa ngưỡng điểm (VD >90% tổng tối đa) → mở khóa level/ trang phục đặc biệt.
- **Leaderboard theo điểm số** cho từng màn, khuyến khích chơi lại để cải thiện thành tích.
- **"Steady hand" bonus:** giữ quỹ đạo rơi mượt (ít lắc tilt đột ngột) → thưởng điểm, khuyến khích kiểm soát tinh tế.

---

## 9. Độ khó & Cấu trúc Level (Difficulty & Level Design)

Các biến số tăng dần theo độ khó:
- Số lượng & tốc độ chướng ngại vật.
- Cường độ và tần suất gió (wind zone, gust, turbulence).
- Kích thước hồng tâm thu hẹp dần / thêm hồng tâm di chuyển.
- Tốc độ rơi của nhân vật.
- Số lượng nhân vật thả mỗi màn & ngưỡng điểm yêu cầu.

*(Đề xuất: xây dựng bảng độ khó chi tiết theo từng level trong tài liệu riêng — Level Design Sheet.)*

---

## 10. Giao diện & UX

- Chỉ báo góc nghiêng hiện tại (mini la bàn/thanh góc ở góc màn hình).
- Vệt quỹ đạo mờ phía sau nhân vật để cảm nhận vận tốc/hướng.
- Rung máy (haptic feedback) khi có gust bất ngờ.
- Đếm ngược trực quan trước mỗi lần tự động thả nhân vật.

---

## 11. Vấn đề cần lưu ý (Risks & Considerations)

- **Tilt control** không phù hợp khi chơi ở nơi bất tiện (xe bus, nằm nghiêng) → cân nhắc chế độ thay thế.
- Cần **calibrate** góc "0 độ" mỗi ván để phù hợp tư thế cầm máy khác nhau.
- Tilt liên tục làm hao pin & có thể gây mỏi tay nếu level kéo dài — cân đối thời lượng mỗi màn.
- Cân bằng giữa gió (obstacle ngẫu nhiên) và tính công bằng — luôn có tín hiệu cảnh báo trước khi gây ảnh hưởng mạnh.

---
### 12. Công thức vật lý chi tiết cho cơ chế Tilt + Wind
#### 12.1. Hệ trục & các biến cơ bản

```
Trục Y: dương hướng xuống (chiều rơi)
Trục X: dương hướng phải

position.x, position.y   : vị trí hiện tại
velocity.x, velocity.y   : vận tốc hiện tại
tiltAngle                : góc nghiêng máy đọc từ gyroscope (độ, - trái / + phải)
```

---

#### 12.2. Rơi theo chiều dọc (Y-axis)

Đơn giản nhưng cần **giới hạn tốc độ tối đa (terminal velocity)** để người chơi luôn có đủ thời gian phản ứng:

```
GRAVITY = 800           // đơn vị: px/s²  (tinh chỉnh theo kích thước màn hình)
MAX_FALL_SPEED = 500     // px/s — tốc độ rơi tối đa

velocity.y += GRAVITY * deltaTime
velocity.y = min(velocity.y, MAX_FALL_SPEED)
position.y += velocity.y * deltaTime
```

**Gợi ý cảm giác thoải mái:** cho `velocity.y` tăng theo easing (không tuyến tính 100%) trong 0.3s đầu tiên sau khi thả — mô phỏng cảm giác "rơi tự do" chứ không giật cục ngay từ đầu:

```
if (fallTime < 0.3):
	velocity.y = GRAVITY * fallTime * easeOutQuad(fallTime / 0.3)
```

---

#### 12.3. Lực Tilt (input chính của người chơi)

##### 12.3.1. Vùng chết (Dead zone) + chuẩn hóa góc

```
DEAD_ZONE = 4°           // độ lệch nhỏ hơn giá trị này = coi như không nghiêng
MAX_TILT_ANGLE = 35°      // vượt quá góc này, lực không tăng thêm

rawAngle = tiltAngle - calibratedZeroAngle   // đã trừ mốc hiệu chỉnh đầu ván

if (abs(rawAngle) < DEAD_ZONE):
	effectiveAngle = 0
else:
	// Dịch chuyển về 0 ngay tại biên dead zone để tránh "giật" khi vừa vượt ngưỡng
	sign = rawAngle > 0 ? 1 : -1
	effectiveAngle = sign * (abs(rawAngle) - DEAD_ZONE)

// Chuẩn hóa về khoảng [-1, 1]
normalizedTilt = clamp(effectiveAngle / (MAX_TILT_ANGLE - DEAD_ZONE), -1, 1)
```

##### 12.3.2. Đường cong phi tuyến (Response Curve)

Đây là phần quan trọng nhất cho **cảm giác thoải mái**: dùng hàm mũ (power curve) thay vì tuyến tính, để nghiêng nhẹ → phản ứng nhẹ nhàng dễ kiểm soát, nghiêng mạnh → phản ứng dứt khoát hơn:

```
TILT_CURVE_POWER = 1.6   // >1 = nhẹ đầu, mạnh cuối. Thử nghiệm 1.4–2.0

curvedTilt = sign(normalizedTilt) * pow(abs(normalizedTilt), TILT_CURVE_POWER)
```

##### 12.3.3. Lực tilt cuối cùng

```
TILT_FORCE_MAX = 600     // px/s² — gia tốc ngang tối đa do tilt gây ra

tiltForce = curvedTilt * TILT_FORCE_MAX
```

---

#### 12.4. Lực gió môi trường (Obstacle)

```
windForce = windZoneStrength * windDirection   // do level design quy định

// Nếu đang trong turbulence: giảm hiệu lực tilt của người chơi tạm thời
if (inTurbulenceZone):
	tiltForce *= turbulenceMultiplier   // ví dụ 0.4–0.6, KHÔNG nên về 0 hoàn toàn
										  // (mất quyền kiểm soát 100% gây ức chế mạnh)
```

**Nguyên tắc thoải mái:** không bao giờ để gió lấy đi hoàn toàn quyền kiểm soát của người chơi — luôn giữ tối thiểu ~30-40% hiệu lực tilt ngay cả ở vùng khó nhất.

---

#### 12.5. Tổng hợp lực & Damping (độ trễ mượt)

```
DAMPING = 3.5   // hệ số cản, càng cao thì vận tốc "bám" theo lực mới càng nhanh

totalForce.x = tiltForce + windForce

// Dùng lerp/exponential smoothing thay vì cộng dồn trực tiếp
// → tạo cảm giác quán tính "mềm" thay vì phản ứng cứng nhắc
targetVelocityX = totalForce.x * responseTimeConstant
velocity.x += (targetVelocityX - velocity.x) * (1 - exp(-DAMPING * deltaTime))

MAX_HORIZONTAL_SPEED = 350
velocity.x = clamp(velocity.x, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)

position.x += velocity.x * deltaTime
```

**Độ nhạy tăng theo độ cao giảm dần** (đã bàn ở phần trước) — tăng `DAMPING` khi gần đất để tạo cảm giác "chỉnh gấp" nhưng vẫn kịp phản ứng:

```
heightRatio = 1 - (position.y / totalFallDistance)   // 0 → 1 khi gần đất
currentDamping = lerp(DAMPING, DAMPING * 1.8, heightRatio)
```

---

#### 12.6. Coyote Time — áp dụng vào 3 điểm

Coyote Time gốc = "vẫn cho nhảy dù đã rời platform vài frame". Tinh thần cốt lõi là: **hành động của người chơi được đánh giá theo ý định gần nhất, không theo timing tuyệt đối khắt khe**. Áp dụng vào game này theo 3 hướng:

#### 12.6.1. Collision Forgiveness (quan trọng nhất)

Hitbox va chạm với vật cản nên **nhỏ hơn hitbox hiển thị (visual)** một khoảng nhất định, cộng thêm 1 khung thời gian "khoan dung" trước khi tính là va chạm thật:

```
VISUAL_HITBOX_SCALE = 1.0
COLLISION_HITBOX_SCALE = 0.75   // hitbox thật nhỏ hơn 25% so với hình vẽ

COYOTE_COLLISION_WINDOW = 0.08s  // ~5 frame ở 60fps

onOverlapDetected(obstacle):
	overlapTimer += deltaTime
	if (overlapTimer > COYOTE_COLLISION_WINDOW):
		triggerCollisionFail()
	// Nếu overlap biến mất trước khi hết window → không tính va chạm
```

→ Người chơi "sượt qua" vật cản trong gang tấc vẫn được bỏ qua, tạo cảm giác "mình né được nhờ phản xạ" thay vì "thua vì pixel-perfect khắt khe".

#### 12.6.2. Input Buffering cho Tilt (bù đắp độ trễ phản xạ con người)

Nếu người chơi tilt đúng hướng **ngay trước** một khoảnh khắc quan trọng (VD: sắp vào vùng gió mạnh) nhưng tín hiệu tới hơi muộn do độ trễ cảm biến/phản xạ, vẫn cho phép input đó có hiệu lực sớm hơn 1 chút:

```
INPUT_BUFFER_WINDOW = 0.1s

if (playerTiltedSignificantly() && timeSinceHazardTriggered < INPUT_BUFFER_WINDOW):
	applyTiltEffectRetroactively()
```

→ Giảm cảm giác "tôi bấm đúng lúc rồi mà vẫn thua vì trễ vài mili giây".

#### 12.6.3. Landing Assist (Coyote cho việc đáp hồng tâm)

Khi nhân vật chạm đất **rất sát rìa** giữa 2 vòng điểm (VD: lệch tâm vòng 70 điểm chỉ 1-2px), làm tròn có lợi cho người chơi:

```
LANDING_ASSIST_MARGIN = 6px   // ~ nửa kích thước nhân vật

distanceToZoneBoundary = abs(landingDistance - zoneBoundaryRadius)
if (distanceToZoneBoundary < LANDING_ASSIST_MARGIN && landingDistance > zoneBoundaryRadius):
	// Đang ở ngoài vòng cao hơn 1 chút → kéo vào vòng cao hơn
	scoreZone = higherZone
```

→ Tránh cảm giác ấm ức "rõ ràng nhìn như trúng tâm mà tính điểm thấp".

---

#### 12.7. Tổng kết pipeline mỗi frame

```
1. Đọc tiltAngle từ gyroscope → tính tiltForce (dead zone + curve)
2. Lấy windForce từ vùng hiện tại (nếu có turbulence thì giảm tiltForce)
3. Tổng hợp lực → smoothing/damping → cập nhật velocity.x
4. Cập nhật velocity.y theo gravity (có easing đầu ván)
5. Cập nhật position.x/y
6. Check overlap va chạm → áp dụng Collision Forgiveness window
7. Check input buffer cho các sự kiện vừa xảy ra
8. Nếu chạm đất → áp dụng Landing Assist → tính điểm theo vòng
```

---

#### 12.8. Bảng thông số khởi điểm để tinh chỉnh (tuning sheet)

| Thông số | Giá trị đề xuất | Ghi chú |
|---|---|---|
| GRAVITY | 800 px/s² | Điều chỉnh theo tổng quãng đường rơi mong muốn |
| MAX_FALL_SPEED | 500 px/s | |
| DEAD_ZONE | 4° | Test thật trên máy, có thể cần 3–6° tùy độ nhạy cảm biến |
| MAX_TILT_ANGLE | 35° | |
| TILT_CURVE_POWER | 1.6 | Thử 1.4 (mượt hơn) đến 2.0 (dứt khoát hơn) |
| TILT_FORCE_MAX | 600 px/s² | |
| DAMPING | 3.5 → 6.3 (gần đất) | |
| COLLISION_HITBOX_SCALE | 0.75 | Không nên xuống dưới 0.6 (quá dễ) |
| COYOTE_COLLISION_WINDOW | 0.08s | |
| INPUT_BUFFER_WINDOW | 0.1s | |
| LANDING_ASSIST_MARGIN | 6px | Tùy kích thước nhân vật/hồng tâm |

**Lưu ý quan trọng:** tất cả con số trên chỉ là điểm khởi đầu — cần **playtest thật trên thiết bị** vì cảm giác tilt phụ thuộc rất nhiều vào độ nhạy cảm biến từng dòng máy Android (khác nhau đáng kể giữa các hãng).

Bạn có muốn mình bổ sung phần này vào file GDD đã tạo trước đó, hoặc viết luôn thành code mẫu (C# cho Unity / Kotlin) để bạn cắm thẳng vào project không?

---
## 13. Việc cần làm tiếp theo (Next Steps)

- [ ] Thiết kế layout hồng tâm + vị trí gió cho level mẫu đầu tiên.
- [ ] Xây dựng bảng độ khó (difficulty curve) qua các level.
- [ ] Thiết kế bộ nhân vật, chướng ngại vật, hiệu ứng hình ảnh chi tiết.
- [ ] Prototype cơ chế tilt + wind trên thiết bị thật để kiểm tra cảm giác chơi (game feel).

---

*Tài liệu này tổng hợp từ quá trình brainstorm, cần cập nhật liên tục khi ý tưởng phát triển thêm.*
