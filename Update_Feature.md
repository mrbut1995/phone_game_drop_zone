# UPDATE FEATURE — Bổ sung & Thay đổi sau Mockup

*Tài liệu này ghi lại các thay đổi được áp dụng dựa trên bản mockup thực tế, bổ sung cho `General_Idea.md` (GDD gốc). Đọc kèm tài liệu gốc để nắm toàn bộ ngữ cảnh.*

---

## 1. Vật phẩm mới trên màn hình (Items)

Ba loại item xuất hiện random trên đường rơi, nhân vật bay ngang qua để thu thập (không cần chạm chính xác, có thể để hitbox thu thập rộng hơn hitbox va chạm chút để dễ nhặt):

### 1.1. Coin
- Thu thập dọc đường rơi, dùng làm **currency** cho hệ thống progression/shop (mở khóa skin, trang phục nhân vật, v.v.)
- Không ảnh hưởng vật lý hay điểm số landing — chỉ là lớp thưởng phụ để tăng engagement trong lúc rơi.

### 1.2. Barrier (Item bảo vệ nhân vật)
- Khi thu thập, tạo 1 lớp bảo vệ tạm thời quanh nhân vật, **miễn 1 lần va chạm** với chướng ngại vật (obstacle) trong quá trình rơi tiếp theo.
- Dùng 1 lần rồi mất hiệu lực (consume-on-hit).

**Gợi ý đặt tên cho item này:**
| Tên đề xuất | Sắc thái |
|---|---|
| **Shield Bubble** | Trực quan, dễ hiểu quốc tế |
| **Aegis** | Ngắn, sang, dễ làm icon (lá chắn tròn) |
| **Guardian Charm** | Gợi cảm giác "phù hộ", hợp phong cách casual dễ thương |
| **Safe Bubble** | Đơn giản, thân thiện, dễ dịch đa ngôn ngữ |
| **Lá Chắn Gió** *(nếu đặt tên tiếng Việt)* | Gắn liền với chủ đề gió của game |

→ Cá nhân đề xuất **"Shield Bubble"** hoặc **"Aegis"** vì ngắn, dễ đưa vào UI, dễ làm icon hình tròn phát sáng bao quanh nhân vật.

### 1.3. Item thêm nhân vật (Extra Character)
- Khi thu thập, **thêm 1 nhân vật vào hàng chờ thả** (bù lại cho lượt đã thất bại trước đó, hoặc tăng tổng số lượt trong màn).

**Gợi ý đặt tên cho item này:**
| Tên đề xuất | Sắc thái |
|---|---|
| **Reinforcement** | Gợi cảm giác "viện trợ thêm quân", hợp chủ đề nhảy dù/quân sự nhẹ |
| **Backup Chute** | Trực tiếp nhắc tới dù dự phòng |
| **Squad Call** | Hiện đại, hợp phong cách game casual |
| **Extra Trooper** | Đơn giản, rõ nghĩa |
| **Dù Cứu Viện** *(tiếng Việt)* | |

→ Đề xuất **"Backup Chute"** (rõ nghĩa, gắn trực tiếp với chủ đề dù) hoặc **"Reinforcement"** (ngắn, dễ đưa vào thông báo "+1 Reinforcement!").

### 1.4. Bảng tổng hợp Item

| Item | Hiệu ứng | Icon gợi ý | Tần suất xuất hiện đề xuất |
|---|---|---|---|
| Coin | +Currency, dùng cho shop/progression | Xu tròn vàng | Thường xuyên (nhiều nhất) |
| Shield Bubble / Aegis | Miễn 1 va chạm obstacle | Bong bóng khiên phát sáng | Trung bình — hiếm hơn coin |
| Backup Chute / Reinforcement | +1 nhân vật vào hàng chờ thả | Icon dù nhỏ có dấu "+" | Hiếm — item giá trị cao |

---

## 2. Continuous Drop System — Thả nhân vật liên tục

**Thay đổi cốt lõi:** Bỏ mô hình "theo lượt" (chờ nhân vật trước rơi xong mới thả nhân vật sau). Thay vào đó:

- Nhân vật mới được thả theo **chu kỳ thời gian cố định** (spawn interval), **không chờ** nhân vật trước chạm đất.
- Nhiều nhân vật cùng tồn tại trên màn hình, mỗi nhân vật ở một giai đoạn rơi khác nhau (một vừa thả, một đang giữa đường, một gần chạm đất).

### 2.1. Thông số cần định nghĩa
```
SPAWN_INTERVAL = 1.2s        // thời gian giữa 2 lần thả liên tiếp (tinh chỉnh theo độ khó)
MAX_CONCURRENT_CHARACTERS = 4 // giới hạn số nhân vật tồn tại đồng thời, tránh rối màn hình
```

- Nếu đã đạt `MAX_CONCURRENT_CHARACTERS`, tạm hoãn spawn cho đến khi có nhân vật chạm đất/kết thúc lượt.
- Vị trí thả (spawn X) của mỗi nhân vật nên có **offset nhẹ theo chu kỳ xen kẽ** (zigzag hoặc random trong 1 khoảng cho phép) để tránh các nhân vật chồng thẳng cột lên nhau, gây khó phân biệt.

### 2.2. Vì sao thay đổi này quan trọng
- Tạo cảm giác **liên tục, dồn dập** hơn so với chờ-từng-lượt — giữ nhịp game nhanh, casual hơn.
- Tăng độ khó tự nhiên: người chơi phải xử lý **nhiều mục tiêu cùng lúc** bằng **một input tilt duy nhất** (xem mục 3).

---

## 3. Unified Tilt — Tilt tác động đồng thời lên toàn bộ nhân vật

**Hệ quả trực tiếp của Continuous Drop:** vì tilt là lực toàn cục (global), khi có nhiều nhân vật cùng rơi, **một lần nghiêng máy sẽ ảnh hưởng đồng thời đến tất cả nhân vật đang tồn tại trên màn hình**, bất kể nhân vật đó vừa thả hay đang gần chạm đất.

### 3.1. Hệ quả gameplay cần thiết kế thêm
- Vì tất cả nhân vật chịu **cùng 1 tiltForce**, nhưng đang ở **độ cao khác nhau** → theo công thức đã có ở GDD gốc (mục 12.5), độ cao khác nhau dẫn đến `currentDamping` khác nhau → **các nhân vật sẽ phản ứng với tilt không hoàn toàn giống nhau về tốc độ dịch chuyển ngang**, dù cùng chịu 1 lực. Đây là điểm hay tự nhiên sinh ra từ hệ vật lý cũ, cần giữ lại vì tạo độ khó có ý nghĩa (không phải toàn bộ nhân vật dính chùm di chuyển y hệt nhau).
- **Tình huống chiến thuật buộc phải đánh đổi:** nếu 2 nhân vật cần 2 hướng né khác nhau (VD: 1 cần né trái để tránh máy bay, 1 cần né phải để vào đúng hồng tâm), người chơi **không thể cứu cả 2** — đây là nguồn tạo kịch tính chính của cơ chế mới, cần tận dụng trong level design (xem mục 6).

### 3.2. Cân nhắc UI/UX
- Cần **highlight/làm nổi bật nhân vật "gần chạm đất nhất"** (VD: viền sáng nhẹ) để người chơi biết nên ưu tiên quan sát ai trong khoảnh khắc quyết định.
- Consider thêm **mini-indicator** (chấm nhỏ ở rìa màn hình) nếu nhân vật đang gần bị obstacle mà người chơi có thể không để ý vì đang tập trung nhân vật khác.

---

## 4. Giảm tốc độ rơi (Slower Fall Speed)

Vì giờ nhiều nhân vật cùng hiện diện trên màn hình, cần **giảm tốc độ rơi** để:
- Đủ thời gian cho nhiều nhân vật cùng hiển thị rõ ràng trên khung hình mà không chồng chéo quá nhanh.
- Người chơi có đủ thời gian phản ứng khi phải theo dõi nhiều mục tiêu cùng lúc.

### 4.1. Điều chỉnh thông số vật lý (so với bảng tuning ở GDD gốc, mục 12.8)

| Thông số | Giá trị cũ | Giá trị mới đề xuất | Ghi chú |
|---|---|---|---|
| GRAVITY | 800 px/s² | **450–500 px/s²** | Giảm ~40% để kéo dài thời gian rơi |
| MAX_FALL_SPEED | 500 px/s | **300 px/s** | Giảm tốc độ trần, tăng thời gian tồn tại trên màn hình |
| Thời gian rơi trung bình (ước tính) | ~1.5–2s | **~3–4s** | Đủ để 2-3 nhân vật cùng hiện diện với SPAWN_INTERVAL ~1.2s |

*(Các thông số khác như TILT_FORCE_MAX, DAMPING, DEAD_ZONE giữ nguyên tinh thần, nhưng cần playtest lại vì tỉ lệ tốc độ rơi/tốc độ ngang thay đổi sẽ ảnh hưởng đến "góc rơi" cảm nhận được.)*

### 4.2. Cân nhắc thêm
- Giảm tốc độ rơi cũng đồng nghĩa **thời gian chịu ảnh hưởng gió dài hơn** → có thể cần giảm nhẹ cường độ gió (`windZoneStrength`) tương ứng để tránh độ khó tăng đột biến ngoài ý muốn.

---

## 5. Wind Clock — Đồng hồ chỉ hướng gió (thay thế thông báo dạng chữ/icon)

**Thay đổi:** Bỏ cách cảnh báo gió bằng icon nhấp nháy/thông báo text (đã đề xuất ở bản GDD gốc mục 5), thay bằng **một đồng hồ kim chỉ hướng gió (wind clock)** hiển thị liên tục trên màn hình.

### 5.1. Thiết kế cơ bản
- Một **mặt đồng hồ tròn nhỏ** cố định ở góc màn hình (VD: trên cùng, không che khu vực nhân vật rơi).
- **Kim chính:** chỉ hướng gió hiện tại — góc kim tương ứng trực tiếp với hướng lực gió đang tác động (12h = không gió/gió trung hòa, lệch theo chiều kim đồng hồ tương ứng hướng trái/phải theo quy ước riêng của game).
- **Độ dài hoặc độ dày kim / màu kim:** thể hiện **cường độ gió** — kim ngắn/mỏng = gió yếu, kim dài/dày hoặc đổi màu (VD: xanh → vàng → đỏ) = gió mạnh.

### 5.2. Dự báo gió sắp tới (thay cho cảnh báo Gust cũ)
- Thêm **kim phụ mờ (ghost needle)** quay dần về vị trí sẽ xảy ra trong 0.5–1s tới — kim phụ "dẫn trước" kim chính, giúp người chơi thấy trước xu hướng thay đổi mà không cần popup/icon cảnh báo riêng.
- Khi có **Gust (gió giật)** sắp xảy ra: kim phụ vọt nhanh ra xa tâm đồng hồ trước khi kim chính "đuổi theo" — tạo cảm giác dự báo tự nhiên, không cần chữ thông báo.

### 5.3. Lý do thiết kế này tốt hơn
- Thông tin **liên tục, luôn hiện diện** (ambient information) thay vì ngắt quãng (thông báo/popup) — phù hợp hơn với nhịp game nhanh, nhiều nhân vật cùng lúc.
- Người chơi có thể **liếc nhìn nhanh** mà không cần dừng theo dõi nhân vật đang rơi.
- Dễ mở rộng thêm chi tiết sau này (VD: vòng ngoài đồng hồ hiển thị thêm turbulence zone sắp tới bằng 1 dải màu riêng).

---

## 6. Ý tưởng bổ sung thêm (theo yêu cầu)

Dưới đây là các ý tưởng mới nảy ra trực tiếp từ 4 thay đổi trên, giúp tận dụng tối đa cơ chế mới và bù đắp các rủi ro gameplay có thể phát sinh:

### 6.1. Giải quyết vấn đề "tilt đồng nhất làm mất chiến thuật"
Vì tilt ảnh hưởng tất cả nhân vật giống nhau, cần cơ chế tạo sự khác biệt giữa các nhân vật để tránh cảm giác đơn điệu:
- **Trọng lượng nhân vật khác nhau (Weight variants):** một số nhân vật "nặng" hơn (ít bị tilt/gió ảnh hưởng, rơi nhanh hơn), một số "nhẹ" hơn (dễ bị đẩy lệch, rơi chậm hơn) — random nhẹ giữa các lượt thả để tạo biến thiên tự nhiên trong phản ứng, dù cùng chịu 1 tiltForce.
- **Nhân vật vàng/đặc biệt (Priority Character):** xuất hiện hiếm, đáp trúng tâm cho điểm gấp đôi — buộc người chơi phải **ưu tiên** hi sinh nhân vật thường để dồn tilt cứu nhân vật đặc biệt khi xảy ra xung đột hướng.

### 6.2. Quản lý rối mắt khi nhiều nhân vật cùng màn hình
- **Color-coding nhân vật theo thứ tự thả** (VD: nhân vật thả trước có màu dù đậm hơn, thả sau nhạt hơn) — giúp người chơi phân biệt ai "gần đất nhất" bằng thị giác nhanh, không cần tính toán.
- **Đường dẫn mờ (trail) riêng cho mỗi nhân vật**, độ đậm trail tăng dần khi gần chạm đất — tự nhiên hướng mắt người chơi về nhân vật cần xử lý gấp nhất.

### 6.3. Cân bằng độ khó với Continuous Drop
- **Giới hạn động (dynamic spawn):** nếu người chơi đang xử lý tệ (nhiều nhân vật gần obstacle cùng lúc), tạm giãn `SPAWN_INTERVAL` ra một chút để giảm tải — tránh cảm giác bị "dồn ép" quá mức ở người chơi mới.
- **Combo xử lý đồng thời (Multi-catch bonus):** nếu 2+ nhân vật đáp đất cùng lúc (hoặc trong khung thời gian rất ngắn) đều trúng vùng điểm cao → thưởng điểm bonus, khuyến khích người chơi cố gắng "cân" nhiều nhân vật cùng lúc thay vì chỉ tập trung 1.

### 6.4. Tận dụng Wind Clock cho mục tiêu phụ
- **Thử thách "đọc gió":** thêm thành tích/nhiệm vụ phụ như "hạ cánh chính xác 3 lần liên tiếp khi kim gió nằm trong vùng đỏ (gió mạnh)" — biến việc quan sát đồng hồ gió từ thông tin phụ trợ thành 1 kỹ năng được thưởng riêng.

### 6.5. Vòng lặp thu thập Item trong lúc rơi
- Vì giờ nhân vật rơi lâu hơn (mục 4) và có nhiều nhân vật cùng lúc, thời gian "trên không" trở thành khoảng không gian đáng khai thác:
  - Thiết kế **cụm coin theo hình dạng** (đường thẳng, vòng cung) để khuyến khích người chơi lái nhân vật đi theo 1 quỹ đạo cụ thể để nhặt hết — tạo mini-goal trong lúc chờ chạm đất.
  - Item **Shield Bubble/Backup Chute** nên xuất hiện ở vị trí **hơi lệch khỏi đường rơi tự nhiên** (không thẳng cột với hồng tâm) để buộc người chơi phải đánh đổi: lệch hướng một chút để nhặt item hữu ích, hoặc bỏ qua để giữ quỹ đạo chính xác vào tâm.

### 6.6. Camera & Framing
- Với nhiều nhân vật rơi trải dài theo thời gian, cân nhắc **camera zoom out nhẹ** hoặc kéo dài khung hình theo chiều dọc để vẫn thấy được cả nhân vật gần đất và nhân vật vừa thả trong cùng 1 khung nhìn, tránh cắt mất thông tin quan trọng.

---

## 7. Tác động lên tài liệu gốc (Cross-reference)

| Mục trong `General_Idea.md` | Thay đổi |
|---|---|
| §2 Core Gameplay Loop | Cập nhật lại bước 1–2: thả liên tục theo chu kỳ, không theo lượt |
| §3 Controls | Bổ sung ghi chú: tilt là lực **toàn cục**, ảnh hưởng đồng thời mọi nhân vật đang tồn tại |
| §5 Hệ thống Gió | Thay cơ chế cảnh báo bằng icon/rung → **Wind Clock** (mục 5 ở đây) |
| §10 Giao diện & UX | Thêm Wind Clock vào danh sách UI chính; bổ sung color-coding nhân vật, highlight nhân vật gần đất nhất |
| §12.8 Tuning Sheet | Cập nhật `GRAVITY`, `MAX_FALL_SPEED` theo bảng mục 4.1 ở đây; thêm `SPAWN_INTERVAL`, `MAX_CONCURRENT_CHARACTERS` |

---

## 8. Việc cần làm tiếp theo (Next Steps cho bản update này)

- [ ] Chốt tên chính thức cho 2 item (Shield/Barrier item và Extra Character item).
- [ ] Playtest lại toàn bộ physics với `GRAVITY`/`MAX_FALL_SPEED` mới để đảm bảo cảm giác rơi vẫn "thoải mái" như mục tiêu ban đầu.
- [ ] Thiết kế chi tiết UI Wind Clock (kích thước, vị trí, animation kim phụ dự báo).
- [ ] Thiết kế thuật toán spawn offset (zigzag/random) để tránh nhân vật chồng cột khi thả liên tục.
- [ ] Xây dựng level mẫu có tình huống "xung đột hướng" giữa 2+ nhân vật để kiểm chứng độ khó chiến thuật mới.
- [ ] Xác định tần suất rơi của từng loại Item (Coin/Shield/Backup Chute) theo từng độ khó level.

---

*Tài liệu này bổ sung cho `General_Idea.md`, cần đọc song song và đồng bộ khi có thay đổi tiếp theo.*