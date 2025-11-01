using Dapper;
using RUoW.Interfaces;
using RUoW.Models;
using System.Data;

namespace RUoW.Repos;

public class AppointmentRepository : IAppointmentRepository
{
    private readonly IDbConnection _connection;
    private readonly IDbTransaction _transaction;

    public AppointmentRepository(IDbConnection connection, IDbTransaction transaction)
    {
        _connection = connection;
        _transaction = transaction;
    }

    public async Task<IEnumerable<DoctorScheduleView>> GetTodaysScheduleAsync()
    {
        // 3. Використання РОЗРІЗУ (VIEW)
        var sql = "SELECT * FROM v_doctor_schedule_today";
        return await _connection.QueryAsync<DoctorScheduleView>(sql, transaction: _transaction);
    }

    public async Task<bool> IsDoctorAvailableAsync(Guid doctorId, DateTime checkTime)
    {
        // 4. Використання ФУНКЦІЇ (FUNCTION)
        var sql = "SELECT dbo.fn_is_doctor_available(@p_doctor_id, @p_check_time)";
        var parameters = new
        {
            p_doctor_id = doctorId,
            p_check_time = checkTime
        };

        // ExecuteScalarAsync - для запитів, що повертають одне значення
        return await _connection.ExecuteScalarAsync<bool>(sql, parameters, transaction: _transaction);
    }

    public async Task CreateAppointmentAsync(Guid patientId, Guid doctorId, DateTime appDate, Guid createdByUserId)
    {
        // 5. Використання ЗБЕРЕЖЕНОЇ ПРОЦЕДУРИ
        var parameters = new
        {
            p_patient_id = patientId,
            p_doctor_id = doctorId,
            p_appointment_date = appDate,
            p_user_id = createdByUserId
        };

        await _connection.ExecuteAsync(
            "sp_create_appointment",
            parameters,
            commandType: CommandType.StoredProcedure,
            transaction: _transaction
        );
    }

    public async Task UpdateAppointmentStatusAsync(Guid appointmentId, string newStatus, Guid updatedByUserId)
    {
        // 6. Використання ЗБЕРЕЖЕНОЇ ПРОЦЕДУРИ
        var parameters = new
        {
            p_appointment_id = appointmentId,
            p_new_status = newStatus,
            p_user_id = updatedByUserId
        };

        await _connection.ExecuteAsync(
            "sp_update_appointment_status",
            parameters,
            commandType: CommandType.StoredProcedure,
            transaction: _transaction
        );
    }
}
