CREATE TRIGGER trg_Patients_Audit_Update
ON Patients
AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE p
    SET updated_at = SYSDATETIMEOFFSET()
    FROM Patients AS p
    INNER JOIN inserted AS i ON p.id = i.id;
END;
GO

CREATE TRIGGER trg_Appointments_Audit_Update
ON Appointments
AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;
    
    UPDATE a
    SET updated_at = SYSDATETIMEOFFSET()
    FROM Appointments AS a
    INNER JOIN inserted AS i ON a.id = i.id;
END;
GO

CREATE TRIGGER trg_MedicalRecords_Audit_Update
ON MedicalRecords
AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE mr
    SET updated_at = SYSDATETIMEOFFSET()
    FROM MedicalRecords AS mr
    INNER JOIN inserted AS i ON mr.id = i.id;
END;
GO

CREATE TRIGGER trg_Prescriptions_Audit_Update
ON Prescriptions
AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE p
    SET updated_at = SYSDATETIMEOFFSET()
    FROM Prescriptions AS p
    INNER JOIN inserted AS i ON p.id = i.id;
END;