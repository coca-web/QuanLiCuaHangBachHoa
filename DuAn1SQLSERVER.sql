------------------------------------------------------------
-- 1. TẠO DATABASE MỚI
------------------------------------------------------------
CREATE DATABASE DuAnBachHoa;
GO
USE DuAnBachHoa;
GO

------------------------------------------------------------
-- 2. TẠO BẢNG
------------------------------------------------------------

CREATE TABLE LoaiSanPham (
    MaLSP NVARCHAR(10) PRIMARY KEY,
    TenLSP NVARCHAR(100) NOT NULL,
    GhiChu NVARCHAR(255)
);

CREATE TABLE NhaCungCap (
    MaNCC NVARCHAR(10) PRIMARY KEY,
    TenNCC NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(255) NOT NULL,
    SDT NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100)
);

CREATE TABLE SanPham (
    MaSP NVARCHAR(10) PRIMARY KEY,
    TenSP NVARCHAR(100) NOT NULL,
    DonGiaBan MONEY,
    DonGiaNhap MONEY,
    Dvt NVARCHAR(20),
    SoLuongTon FLOAT,
    MaLSP NVARCHAR(10) NOT NULL,
    MaNCC NVARCHAR(10),
    HinhAnh VARBINARY(MAX)
);

CREATE TABLE NhanVien (
    MaNV NVARCHAR(10) PRIMARY KEY,
    TenNV NVARCHAR(100) NOT NULL,
    GioiTinh NVARCHAR(10),
    NgaySinh DATE,
    DiaChi NVARCHAR(200),
    DienThoai NVARCHAR(20),
    Email NVARCHAR(100),
    Luong DECIMAL(18,2),
    TrangThai BIT,
    HinhAnh NVARCHAR(100),
    ChucVu NVARCHAR(50)
);

CREATE TABLE KhachHang (
    MaKH NVARCHAR(10) PRIMARY KEY,
    TenKH NVARCHAR(50) NOT NULL,
    DienThoai NVARCHAR(20) NOT NULL
);

CREATE TABLE PhieuNhap (
    SoPN NVARCHAR(10) PRIMARY KEY,
    NgayNhap DATE NOT NULL,
    PTTT NVARCHAR(50),
    MaNV NVARCHAR(10) NOT NULL,
    MaNCC NVARCHAR(10) NOT NULL,
    TongTien DECIMAL(18,2)
);

CREATE TABLE CTPhieuNhap (
    SoPN NVARCHAR(10) NOT NULL,
    MaSP NVARCHAR(10) NOT NULL,
    SoLuong INT NOT NULL,
    DonGiaNhap MONEY NOT NULL,
    ThanhTien AS (SoLuong * DonGiaNhap) PERSISTED,
    PRIMARY KEY (SoPN, MaSP)
);

CREATE TABLE HoaDon (
    SoHD NVARCHAR(10) PRIMARY KEY,
    NgayHD DATETIME2 NOT NULL,
    PTTT NVARCHAR(50),
    MaNV NVARCHAR(10) NOT NULL,
    MaKH NVARCHAR(10) NOT NULL,
    TongTien MONEY
);

CREATE TABLE CTHoaDon (
    SoHD NVARCHAR(10) NOT NULL,
    MaSP NVARCHAR(10) NOT NULL,
    TenSP NVARCHAR(50) NOT NULL,
    SoLuong INT NOT NULL,
    DonGiaBan MONEY NOT NULL,
    GiamGiaPercent FLOAT DEFAULT 0,
    ThanhTien AS (SoLuong * DonGiaBan * (1 - GiamGiaPercent/100)) PERSISTED,
    PRIMARY KEY (SoHD, MaSP)
);

CREATE TABLE PhieuXuat (
    SoPX NVARCHAR(10) PRIMARY KEY,
    NgayXuat DATE NOT NULL,
    MaNV NVARCHAR(10) NOT NULL,
    TongTien DECIMAL(18,2)
);

CREATE TABLE CTPhieuXuat (
    SoPX NVARCHAR(10) NOT NULL,
    MaSP NVARCHAR(10) NOT NULL,
    SoLuong INT NOT NULL,
    DonGiaXuat MONEY NOT NULL,
    ThanhTien AS (SoLuong * DonGiaXuat) PERSISTED,
    PRIMARY KEY (SoPX, MaSP)
);

CREATE TABLE TaiKhoan (
    TenDN NVARCHAR(50) PRIMARY KEY,
    MatKhau NVARCHAR(50) NOT NULL,
    MaNV NVARCHAR(10) NOT NULL,
    VaiTro BIT NOT NULL DEFAULT 0,
	TrangThai INT NOT NULL DEFAULT 1
);
GO

------------------------------------------------------------
-- 3. THÊM KHÓA NGOẠI
------------------------------------------------------------
ALTER TABLE SanPham
    ADD CONSTRAINT FK_SP_LSP FOREIGN KEY (MaLSP) REFERENCES LoaiSanPham(MaLSP),
        CONSTRAINT FK_SP_NCC FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC);

ALTER TABLE PhieuNhap
    ADD CONSTRAINT FK_PN_NV FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV),
        CONSTRAINT FK_PN_NCC FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC);

ALTER TABLE CTPhieuNhap
    ADD CONSTRAINT FK_CTPN_PN FOREIGN KEY (SoPN) REFERENCES PhieuNhap(SoPN),
        CONSTRAINT FK_CTPN_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP);

ALTER TABLE HoaDon
    ADD CONSTRAINT FK_HD_NV FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV),
        CONSTRAINT FK_HD_KH FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH);

ALTER TABLE CTHoaDon
    ADD CONSTRAINT FK_CTHD_HD FOREIGN KEY (SoHD) REFERENCES HoaDon(SoHD),
        CONSTRAINT FK_CTHD_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP);

ALTER TABLE PhieuXuat
    ADD CONSTRAINT FK_PX_NV FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV);

ALTER TABLE CTPhieuXuat
    ADD CONSTRAINT FK_CTPX_PX FOREIGN KEY (SoPX) REFERENCES PhieuXuat(SoPX),
        CONSTRAINT FK_CTPX_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP);

ALTER TABLE TaiKhoan
    ADD CONSTRAINT FK_TK_NV FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV);
GO

------------------------------------------------------------
-- 4. TRIGGERS

------------------------------------------------------------
-- Tạo tài khoản tự động khi thêm nhân viên
DROP TRIGGER trg_TaoTaiKhoan_NV;
IF OBJECT_ID('trg_TaoTaiKhoan_NV','TR') IS NOT NULL 

    DROP TRIGGER trg_TaoTaiKhoan_NV;
GO

CREATE TRIGGER trg_TaoTaiKhoan_NV ON NhanVien
AFTER INSERT
AS
BEGIN
    INSERT INTO TaiKhoan (TenDN, MatKhau, MaNV, VaiTro, TrangThai)
    SELECT 
        i.MaNV, 
        CONVERT(NVARCHAR(50), FORMAT(i.NgaySinh,'ddMMyyyy')), 
        i.MaNV,
        CASE 
            WHEN i.ChucVu IN ('Admin', 'Quản lý') THEN 1
            ELSE 0
        END,
        i.TrangThai   -- ⭐ Gán trạng thái tài khoản theo trạng thái nhân viên
    FROM inserted i;
END
GO





-- Trừ kho khi bán hàng (CTHoaDon & CTPhieuXuat)
IF OBJECT_ID('trg_BanHang_TruKho','TR') IS NOT NULL DROP TRIGGER trg_BanHang_TruKho;
GO
CREATE TRIGGER trg_BanHang_TruKho ON CTHoaDon
AFTER INSERT
AS
BEGIN
    UPDATE sp
    SET sp.SoLuongTon = sp.SoLuongTon - i.SoLuong
    FROM SanPham sp
    INNER JOIN inserted i ON sp.MaSP = i.MaSP;
END
GO

IF OBJECT_ID('trg_CapNhatKho_XuatHang','TR') IS NOT NULL DROP TRIGGER trg_CapNhatKho_XuatHang;
GO
CREATE TRIGGER trg_CapNhatKho_XuatHang ON CTPhieuXuat
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    -- Thêm
    IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
    BEGIN
        UPDATE sp SET sp.SoLuongTon = sp.SoLuongTon - i.SoLuong
        FROM SanPham sp INNER JOIN inserted i ON sp.MaSP = i.MaSP;
    END
    -- Xóa
    IF EXISTS(SELECT * FROM deleted) AND NOT EXISTS(SELECT * FROM inserted)
    BEGIN
        UPDATE sp SET sp.SoLuongTon = sp.SoLuongTon + d.SoLuong
        FROM SanPham sp INNER JOIN deleted d ON sp.MaSP = d.MaSP;
    END
    -- Cập nhật
    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        UPDATE sp SET sp.SoLuongTon = sp.SoLuongTon - (i.SoLuong - d.SoLuong)
        FROM SanPham sp
        INNER JOIN inserted i ON sp.MaSP = i.MaSP
        INNER JOIN deleted d ON sp.MaSP = d.MaSP;
    END
END
GO

------------------------------------------------------------
-- 5. DỮ LIỆU MẪU
------------------------------------------------------------

-- Nhà cung cấp
INSERT INTO NhaCungCap (MaNCC,TenNCC,DiaChi,SDT,Email)
VALUES 
('NCC01','VinaFood','Bình Thạnh, TP.HCM','0901111222','vinafood@gmail.com'),
('NCC02','PepsiCo VN','Q2, TP.HCM','0902222333','pepsi@gmail.com'),
('NCC03','Unilever VN','Q7, TP.HCM','0903333444','unilever@gmail.com');

-- Loại sản phẩm
INSERT INTO LoaiSanPham (MaLSP,TenLSP,GhiChu)
VALUES 
('LSP01','Thực phẩm khô','Mì, gạo, đồ khô'),
('LSP02','Nước giải khát','Nước ngọt, bia, nước suối'),
('LSP03','Hóa mỹ phẩm','Chất tẩy rửa, chăm sóc cá nhân');
('LSP05','Sữa & chế phẩm từ sữa','Sữa & chế phẩm từ sữa');

-- Nhân viên
INSERT INTO NhanVien (MaNV, TenNV, GioiTinh, NgaySinh, DiaChi, DienThoai, Email, Luong, TrangThai, HinhAnh, ChucVu)
VALUES 
('NV001','Lê Văn Admin',1,'1990-01-01','Quận 1, TP.HCM','0900000001','admin@bachhoa.com',25000000,1,NULL,'Admin'),
('NV003','Võ Chí Vương',1,'2002-02-17','Quận 1, TP.HCM','0367490282','admin@bachhoa.com',25000000,1,NULL,'Quản lí'),
('NV002','Nguyễn Văn Tùng',1,'1995-05-15','Quận 3, TP.HCM','0900000002','tungnv@bachhoa.com',8500000,1,NULL,'Nhân viên');
GO

-- Khách hàng
INSERT INTO KhachHang VALUES
('KH01','Trần Văn A','0901234567'),
('KH02','Lý Thị B','0907654321');

-- Hóa đơn mẫu
INSERT INTO HoaDon (SoHD,NgayHD,PTTT,MaNV,MaKH,TongTien)
VALUES 
('HD001','2025-11-20','Tiền mặt','NV002','KH01',500000),
('HD002','2025-11-20','Chuyển khoản','NV002','KH02',350000),
('HD003','2025-11-21','Tiền mặt','NV002','KH01',700000),
('HD004','2025-11-22','Chuyển khoản','NV002','KH02',100000);
INSERT INTO SanPham (MaSP, TenSP, DonGiaBan, Dvt, SoLuongTon, MaLSP, MaNCC, HinhAnh, DonGiaNhap)
VALUES
('SP01', N'Mì tôm Hảo Hảo', 4500, N'gói', 200, 'LSP01', 'NCC01', NULL, 3500),
('SP02', N'Gạo ST25', 20000, N'kg', 50, 'LSP01', 'NCC01', NULL, 15000),
('SP03', N'Bánh quy Oreo', 18000, N'hộp', 80, 'LSP01', 'NCC01', NULL, 12000),
('SP04', N'Nước ngọt Coca-Cola 330ml', 12000, N'chai', 100, 'LSP02', 'NCC02', NULL, 9000),
('SP05', N'Nước ngọt Pepsi 330ml', 11000, N'chai', 120, 'LSP02', 'NCC02', NULL, 8500),
('SP06', N'Nước suối Aquafina 500ml', 7000, N'chai', 150, 'LSP02', 'NCC02', NULL, 5000),
('SP07', N'Bột giặt OMO 2kg', 95000, N'gói', 60, 'LSP03', 'NCC03', NULL, 70000),
('SP08', N'Nước rửa chén Sunlight 500ml', 30000, N'chai', 80, 'LSP03', 'NCC03', NULL, 20000),
('SP09', N'Sữa tắm Dove 200ml', 85000, N'chai', 40, 'LSP03', 'NCC03', NULL, 60000),
('SP13', N'Sữa Vinamilk 500ml', 15000, N'chai', 100, 'LSP05', 'NCC03', NULL, 12000),
('SP14', N'Sữa tươi TH 1L', 28000, N'chai', 90, 'LSP05', 'NCC03', NULL, 21000),
('SP15', N'Bánh mì sandwich', 25000, N'ổ', 50, 'LSP01', 'NCC01', NULL, 18000),
('SP16', N'Gạo Jasmine 5kg', 180000, N'túi', 30, 'LSP01', 'NCC01', NULL, 140000),
('SP17', N'Mì ăn liền Acecook', 4000, N'gói', 300, 'LSP01', 'NCC01', NULL, 3000),
('SP18', N'Nước ngọt 7Up 330ml', 12000, N'chai', 90, 'LSP02', 'NCC02', NULL, 9000),
('SP19', N'Nước suối Lavie 500ml', 6000, N'chai', 200, 'LSP02', 'NCC02', NULL, 4000),
('SP20', N'Nước ép Vfresh 1L', 45000, N'chai', 60, 'LSP02', 'NCC02', NULL, 35000),
('SP21', N'Bột giặt Tide 2kg', 100000, N'gói', 50, 'LSP03', 'NCC03', NULL, 75000),
('SP22', N'Nước rửa tay Lifebuoy 250ml', 35000, N'chai', 70, 'LSP03', 'NCC03', NULL, 25000),
('SP23', N'Sữa tắm Lux 180ml', 45000, N'chai', 60, 'LSP03', 'NCC03', NULL, 30000),
('SP27', N'Sữa đặc có đường Vinamilk 380g', 21000, N'hộp', 80, 'LSP05', 'NCC03', NULL, 16000),
('SP28', N'Sữa chua uống TH 180ml', 12000, N'chai', 120, 'LSP05', 'NCC03', NULL, 9000),
('SP29', N'Bánh gạo Hàn Quốc', 15000, N'gói', 100, 'LSP01', 'NCC01', NULL, 10000),
('SP30', N'Mì Quảng 500g', 25000, N'gói', 60, 'LSP01', 'NCC01', NULL, 18000),
('SP31', N'Nước ngọt Mirinda 330ml', 12000, N'chai', 80, 'LSP02', 'NCC02', NULL, 9000),
('SP32', N'Nước khoáng Vĩnh Hảo 500ml', 7000, N'chai', 150, 'LSP02', 'NCC02', NULL, 5000),
('SP33', N'Nước ép cam Dimes 1L', 45000, N'chai', 60, 'LSP02', 'NCC02', NULL, 35000),
('SP34', N'Bột giặt Ariel 2kg', 95000, N'gói', 50, 'LSP03', 'NCC03', NULL, 70000),
('SP35', N'Nước rửa chén Sunlight 1L', 55000, N'chai', 70, 'LSP03', 'NCC03', NULL, 40000),
('SP36', N'Sữa tắm Enchanteur 200ml', 90000, N'chai', 40, 'LSP03', 'NCC03', NULL, 65000),
('SP40', N'Sữa Vinamilk 1L', 28000, N'chai', 90, 'LSP05', 'NCC03', NULL, 21000),
('SP41', N'Sữa tươi TH 500ml', 15000, N'chai', 100, 'LSP05', 'NCC03', NULL, 12000),
('SP42', N'Bánh mì đen Sandwich', 30000, N'ổ', 50, 'LSP01', 'NCC01', NULL, 20000),
('SP43', N'Gạo Nhật 5kg', 200000, N'túi', 30, 'LSP01', 'NCC01', NULL, 150000),
('SP44', N'Mì Ly Omachi', 5500, N'gói', 200, 'LSP01', 'NCC01', NULL, 4000),
('SP45', N'Nước ngọt Number One 330ml', 12000, N'chai', 90, 'LSP02', 'NCC02', NULL, 9000),
('SP49', N'Sữa Vinamilk 500ml', 15000, N'chai', 100, 'LSP05', 'NCC03', NULL, 12000),
('SP50', N'Sữa tươi TH 1L', 28000, N'chai', 90, 'LSP05', 'NCC03', NULL, 21000);
