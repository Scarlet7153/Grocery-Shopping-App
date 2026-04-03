1\. Table users

\-         **id:** Mã định danh duy nhất của người dùng (Khóa chính).

\-         **phone\_number:** Số điện thoại, dùng làm tài khoản đăng nhập (không được trùng).

\-         **password\_hash:** Mật khẩu (đã được mã hóa để bảo mật).

\-         **role:** Vai trò của tài khoản (CUSTOMER \- Khách, SHIPPER \- Tài xế, STORE \- Cửa hàng, ADMIN \- Quản trị).

\-         **status:** Trạng thái tài khoản (ACTIVE \- Đang hoạt động, BANNED \- Bị khóa).

\-         **full\_name:** Họ và tên người dùng.

\-         **avatar\_url:** Đường dẫn (link) ảnh đại diện.

\-         **address:** Địa chỉ cá nhân.

\-         **created\_at:** Thời gian tạo tài khoản.

\-         **updated\_at:** Thời gian cập nhật thông tin gần nhất.

2\. Table stores

\-         **id:** Mã định danh cửa hàng (Khóa chính).

\-         **user\_id:** ID của người làm chủ cửa hàng (Liên kết với bảng users).

\-         **store\_name:**  Tên hiển thị của cửa hàng (VD: Tạp hóa cô Ba).

\-         **address:** Địa chỉ thực tế của cửa hàng.

\-         **is\_open:**  Trạng thái cửa hàng (True:  Đang mở cửa / False**:** Tạm đóng cửa).

3\. Table categories

\-         **id:** Mã danh mục (Khóa chính).

\-         **name:**  Tên danh mục (VD: Thực phẩm, Thịt cá...).

\-         **icon\_url:** Đường dẫn hình ảnh biểu tượng của danh mục.

4\. Table products

\-         **id:** Mã sản phẩm (Khóa chính).

\-         **store\_id:** Thuộc cửa hàng nào.

\-         **category\_id:** Thuộc danh mục nào.

\-         **name:**  Tên sản phẩm (VD: Thịt ba rọi heo, Rau muống).

\-         **image\_url:** Đường dẫn hình ảnh sản phẩm.

\-         **description:** Mô tả chi tiết món hàng.

\-         **status:** Tình trạng bán (AVAILABLE \- Còn hàng, HIDDEN \- Ẩn không bán nữa).

5\. Table product\_units

\-         **id:** Mã đơn vị (Khóa chính).

\-         **product\_id:** Thuộc về sản phẩm nào.

\-         **unit\_name:**  Đơn vị bán (VD: Gói 300g, 1 Bó, 1 khay).

\-         **price:**  Nhập giá / Đơn vị đã nhập ở trên.

\-         **stock\_quantity:** Số lượng còn lại trong kho của đơn vị này.

6\. Table orders

\-         **id:** Mã đơn hàng (Khóa chính).

\-         **customer\_id:** ID của khách đặt hàng.

\-         **store\_id:** ID của cửa hàng bán.

\-         **shipper\_id:** ID của tài xế nhận giao (Bỏ trống NULL khi mới đặt, ai nhận đơn thì điền ID vào đây).

\-         **status:** Tình trạng đơn (PENDING \- Chờ xác nhận, PICKING\_UP \- Đang lấy hàng, DELIVERING \- Đang giao, DELIVERED \- Hoàn thành, CANCELLED \- Đã hủy).

\-         **total\_amount:** Tổng tiền hàng hóa.

\-         **shipping\_fee:** Tiền phí vận chuyển.

\-         **delivery\_address:** Địa chỉ cụ thể nơi giao hàng đến.

\-         **pod\_image\_url:** Ảnh bằng chứng (Tài xế chụp khi giao hàng tới nơi).

\-         **cancel\_reason:** Lý do hủy đơn (nếu đơn bị hủy).

\-         **created\_at:** Thời gian đặt hàng.

7\. Table order\_items

\-         **id:** Mã chi tiết (Khóa chính).

\-         **order\_id:** Thuộc về đơn hàng nào.

\-         **product\_unit\_id:**  Khách mua ĐƠN VỊ sản phẩm nào (VD: Mua Gói 300g hay Khay 1kg).

\-         **quantity:** Mua số lượng bao nhiêu.

\-         **unit\_price:** Đơn giá tại thời điểm mua (Lưu lại để sau này giá hàng đổi thì giá trong đơn không bị nhảy theo).

8\. Table payments

\-         **id:** Mã định danh giao dịch (Khóa chính).

\-         **order\_id:** Giao dịch này thuộc về đơn hàng nào (Liên kết với bảng orders).

\-         **payment\_method:** Phương thức thanh toán (COD \- Tiền mặt / MOMO \- Ví Momo).

\-         **amount:** Số tiền của giao dịch này.

\-         **transaction\_code:** Mã giao dịch trả về từ Momo (Lưu lại để làm bằng chứng đối soát). Với COD, trường này bỏ trống (NULL).

\-         **status:** Trạng thái giao dịch (PENDING \- Đang chờ, SUCCESS \- Thành công, FAILED \- Thất bại/Lỗi, REFUNDED \- Đã hoàn tiền).

\-         **created\_at:** Thời gian tạo giao dịch.

\-         **updated\_at:** Thời gian cập nhật trạng thái giao dịch (Lúc Momo báo tiền đã vào tài khoản).

9\. Table reviews

\-         **id:** Mã đánh giá (Khóa chính).

\-         **order\_id:** Đánh giá dựa trên đơn hàng nào.

\-         **reviewer\_id:** ID của khách hàng viết đánh giá.

\-         **store\_id:** Mã ID của Cửa hàng được đánh giá.

\-         **rating:** Điểm số từ 1 đến 5 sao.

\-         **comment:** Nội dung bình luận, lời khen chê.

\-         **created\_at:** Thời gian viết đánh giá.

