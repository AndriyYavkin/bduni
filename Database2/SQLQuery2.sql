-- ============================================================
-- ПОВНИЙ СКРИПТ: СХЕМА + ГЕНЕРАЦІЯ ДАНИХ (MS SQL)
-- ВИПРАВЛЕНО: Прибрано тимчасову процедуру. Генерація даних у фінальному блоці.
-- ============================================================

-- 1. Очищення (Dropping tables in correct dependency order)
-- Якщо VS Code свариться на ці рядки при Build - це нормально для скриптів.
-- Просто виконуйте цей код як запит (Run Query).
IF OBJECT_ID('PrescriptionItems', 'U') IS NOT NULL DROP TABLE PrescriptionItems;
IF OBJECT_ID('Prescriptions', 'U') IS NOT NULL DROP TABLE Prescriptions;
IF OBJECT_ID('RecordDiagnoses', 'U') IS NOT NULL DROP TABLE RecordDiagnoses;
IF OBJECT_ID('Diagnoses', 'U') IS NOT NULL DROP TABLE Diagnoses;
IF OBJECT_ID('Medications', 'U') IS NOT NULL DROP TABLE Medications;
IF OBJECT_ID('Bills', 'U') IS NOT NULL DROP TABLE Bills;
IF OBJECT_ID('Admissions', 'U') IS NOT NULL DROP TABLE Admissions;
IF OBJECT_ID('Rooms', 'U') IS NOT NULL DROP TABLE Rooms;
IF OBJECT_ID('MedicalRecords', 'U') IS NOT NULL DROP TABLE MedicalRecords;
IF OBJECT_ID('Appointments', 'U') IS NOT NULL DROP TABLE Appointments;
IF OBJECT_ID('Doctors', 'U') IS NOT NULL DROP TABLE Doctors;
IF OBJECT_ID('Departments', 'U') IS NOT NULL DROP TABLE Departments;
IF OBJECT_ID('Staff', 'U') IS NOT NULL DROP TABLE Staff;
IF OBJECT_ID('Patients', 'U') IS NOT NULL DROP TABLE Patients;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
GO

-- 2. Створення таблиць
CREATE TABLE Users (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    username NVARCHAR(100) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    [role] NVARCHAR(50) NOT NULL DEFAULT 'Patient',
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE Patients (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER REFERENCES Users(id) ON DELETE SET NULL,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone_number NVARCHAR(20) UNIQUE,
    is_deleted BIT NOT NULL DEFAULT 0,
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET,
    updated_by_user_id UNIQUEIDENTIFIER REFERENCES Users(id)
);
GO

CREATE TABLE Staff (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER REFERENCES Users(id) ON DELETE SET NULL,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    [position] NVARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    is_deleted BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE Departments (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [name] NVARCHAR(150) UNIQUE NOT NULL,
    [description] NVARCHAR(MAX)
);
GO

CREATE TABLE Doctors (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    staff_id UNIQUEIDENTIFIER UNIQUE REFERENCES Staff(id) ON DELETE CASCADE,
    department_id UNIQUEIDENTIFIER REFERENCES Departments(id) ON DELETE SET NULL,
    specialization NVARCHAR(150) NOT NULL
);
GO

CREATE TABLE Appointments (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    patient_id UNIQUEIDENTIFIER NOT NULL REFERENCES Patients(id),
    doctor_id UNIQUEIDENTIFIER NOT NULL REFERENCES Doctors(id),
    appointment_date DATETIME2 NOT NULL,
    [status] NVARCHAR(50) NOT NULL DEFAULT 'Scheduled',
    is_deleted BIT NOT NULL DEFAULT 0,
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET,
    updated_by_user_id UNIQUEIDENTIFIER REFERENCES Users(id)
);
GO

CREATE TABLE MedicalRecords (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    patient_id UNIQUEIDENTIFIER NOT NULL REFERENCES Patients(id),
    appointment_id UNIQUEIDENTIFIER REFERENCES Appointments(id),
    notes NVARCHAR(MAX),
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET,
    updated_by_user_id UNIQUEIDENTIFIER REFERENCES Users(id)
);
GO

CREATE TABLE Diagnoses (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    code NVARCHAR(20) UNIQUE NOT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [description] NVARCHAR(MAX)
);
GO

CREATE TABLE RecordDiagnoses (
    record_id UNIQUEIDENTIFIER NOT NULL REFERENCES MedicalRecords(id) ON DELETE CASCADE,
    diagnosis_id UNIQUEIDENTIFIER NOT NULL REFERENCES Diagnoses(id) ON DELETE NO ACTION,
    PRIMARY KEY (record_id, diagnosis_id)
);
GO

-- 3. ГЕНЕРАЦІЯ ДАНИХ (Окремий Batch)
-- Ми не використовуємо тут процедуру, просто скрипт.
SET NOCOUNT ON;

-- ЗМІННІ (Живуть тільки в цьому блоці до кінця файлу)
DECLARE @deptId UNIQUEIDENTIFIER = NEWID();
DECLARE @staffUserId UNIQUEIDENTIFIER = NEWID();
DECLARE @staffId UNIQUEIDENTIFIER = NEWID();
DECLARE @docId UNIQUEIDENTIFIER = NEWID();

DECLARE @diag1 UNIQUEIDENTIFIER = NEWID();
DECLARE @diag2 UNIQUEIDENTIFIER = NEWID();
DECLARE @diag3 UNIQUEIDENTIFIER = NEWID();

DECLARE @i INT = 1;
DECLARE @j INT;
DECLARE @patientUserId UNIQUEIDENTIFIER;
DECLARE @patientId UNIQUEIDENTIFIER;
DECLARE @appId UNIQUEIDENTIFIER;
DECLARE @recordId UNIQUEIDENTIFIER;

-- А. Додаємо статичні дані
INSERT INTO Departments (id, name, description) VALUES (@deptId, 'General Medicine', 'General checkups');
INSERT INTO Users (id, username, password_hash, role) VALUES (@staffUserId, 'doc_house', 'hash123', 'Doctor');
INSERT INTO Staff (id, user_id, first_name, last_name, position, hire_date) 
VALUES (@staffId, @staffUserId, 'Gregory', 'House', 'Doctor', '2010-01-01');
INSERT INTO Doctors (id, staff_id, department_id, specialization) VALUES (@docId, @staffId, @deptId, 'Diagnostics');

INSERT INTO Diagnoses (id, code, name, description) VALUES 
(@diag1, 'J00', 'Acute nasopharyngitis', 'Common cold'),
(@diag2, 'I10', 'Essential hypertension', 'High blood pressure'),
(@diag3, 'E11', 'Type 2 diabetes mellitus', 'Diabetes type 2');

PRINT 'Starting data generation... Please wait.';

-- Б. Генерація 1000 Пацієнтів
WHILE @i <= 1000
BEGIN
    SET @patientUserId = NEWID();
    INSERT INTO Users (id, username, password_hash, role) 
    VALUES (@patientUserId, 'patient_' + CAST(@i AS NVARCHAR), 'hash', 'Patient');

    SET @patientId = NEWID();
    INSERT INTO Patients (id, user_id, first_name, last_name, date_of_birth, phone_number)
    VALUES (@patientId, @patientUserId, 'Name' + CAST(@i AS NVARCHAR), 'Smith' + CAST(@i AS NVARCHAR), '1980-01-01', '555-' + CAST(@i AS NVARCHAR));

    SET @j = 1;
    WHILE @j <= 5
    BEGIN
        SET @appId = NEWID();
        INSERT INTO Appointments (id, patient_id, doctor_id, appointment_date, status)
        VALUES (@appId, @patientId, @docId, DATEADD(DAY, -@j, SYSDATETIME()), 'Completed');

        SET @recordId = NEWID();
        INSERT INTO MedicalRecords (id, patient_id, appointment_id, notes)
        VALUES (@recordId, @patientId, @appId, 'Patient complains of symptoms type ' + CAST(@j AS NVARCHAR));

        INSERT INTO RecordDiagnoses (record_id, diagnosis_id)
        VALUES (@recordId, CASE WHEN @j % 3 = 0 THEN @diag1 WHEN @j % 3 = 1 THEN @diag2 ELSE @diag3 END);

        SET @j = @j + 1;
    END

    SET @i = @i + 1;
END;

PRINT 'Data generation complete.';
GO