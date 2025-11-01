CREATE PROCEDURE sp_soft_delete_patient
    @p_patient_id UNIQUEIDENTIFIER,
    @p_user_id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Patients
    SET is_deleted = 1,
        updated_by_user_id = @p_user_id
    WHERE id = @p_patient_id;
END;
GO

CREATE PROCEDURE sp_create_appointment
    @p_patient_id UNIQUEIDENTIFIER,
    @p_doctor_id UNIQUEIDENTIFIER,
    @p_appointment_date DATETIME2,
    @p_user_id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @doctor_exists BIT;
    DECLARE @patient_exists BIT;

    SELECT @doctor_exists = CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Doctors d 
            JOIN Staff s ON d.staff_id = s.id 
            WHERE d.id = @p_doctor_id AND s.is_deleted = 0
        ) THEN 1 
        ELSE 0 
    END;

    SELECT @patient_exists = CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Patients 
            WHERE id = @p_patient_id AND is_deleted = 0
        ) THEN 1 
        ELSE 0 
    END;

    IF @doctor_exists = 0
    BEGIN
        ;THROW 50001, 'Doctor does not exist or is inactive.', 1;
        RETURN;
    END;

    IF @patient_exists = 0
    BEGIN
        ;THROW 50002, 'Patient does not exist or is inactive.', 1;
        RETURN;
    END;

    INSERT INTO Appointments (patient_id, doctor_id, appointment_date, updated_by_user_id)
    VALUES (@p_patient_id, @p_doctor_id, @p_appointment_date, @p_user_id);
END;
GO

CREATE FUNCTION fn_is_doctor_available (
    @p_doctor_id UNIQUEIDENTIFIER,
    @p_check_time DATETIME2
)
RETURNS BIT
AS
BEGIN
    DECLARE @is_available BIT;

    SELECT @is_available = CASE 
        WHEN NOT EXISTS (
            SELECT 1
            FROM Appointments
            WHERE doctor_id = @p_doctor_id
              AND appointment_date = @p_check_time
              AND [status] <> 'Canceled'
              AND is_deleted = 0
        ) THEN 1 
        ELSE 0 
    END;

    RETURN @is_available;
END;
GO

CREATE VIEW v_active_patients AS
SELECT
    id,
    user_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    created_at,
    updated_at,
    updated_by_user_id
FROM
    Patients
WHERE
    is_deleted = 0;
GO

CREATE VIEW v_doctor_schedule_today AS
SELECT
    a.id AS appointment_id,
    a.appointment_date,
    a.[status],
    d.id AS doctor_id,
    ds.first_name AS doctor_first_name,
    ds.last_name AS doctor_last_name,
    d.specialization,
    p.id AS patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name
FROM
    Appointments a
JOIN
    Doctors d ON a.doctor_id = d.id
JOIN
    Staff ds ON d.staff_id = ds.id
JOIN
    Patients p ON a.patient_id = p.id
WHERE
    a.is_deleted = 0
    AND ds.is_deleted = 0
    AND p.is_deleted = 0
    AND CAST(a.appointment_date AS DATE) = CAST(GETDATE() AS DATE);
GO

CREATE PROCEDURE sp_update_appointment_status
    @p_appointment_id UNIQUEIDENTIFIER,
    @p_new_status NVARCHAR(50),
    @p_user_id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Appointments
    SET [status] = @p_new_status,
        updated_by_user_id = @p_user_id
    WHERE id = @p_appointment_id AND is_deleted = 0;
END;
GO