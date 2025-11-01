using Dapper;
using RUoW.Interfaces;
using RUoW.Models;
using System.Data;

namespace RUoW.Repos;

public class PatientRepository : IPatientRepository
{
    private readonly IDbConnection _connection;
    private readonly IDbTransaction _transaction;

    public PatientRepository(IDbConnection connection, IDbTransaction transaction)
    {
        _connection = connection;
        _transaction = transaction;
    }

    public async Task<IEnumerable<Patient>> GetActivePatientsAsync()
    {
        // 1. Використання РОЗРІЗУ (VIEW)
        var sql = "SELECT * FROM v_active_patients";
        return await _connection.QueryAsync<Patient>(sql, transaction: _transaction);
    }

    public async Task SoftDeletePatientAsync(Guid patientId, Guid updatedByUserId)
    {
        // 2. Використання ЗБЕРЕЖЕНОЇ ПРОЦЕДУРИ
        var parameters = new
        {
            p_patient_id = patientId,
            p_user_id = updatedByUserId
        };

        await _connection.ExecuteAsync(
            "sp_soft_delete_patient",
            parameters,
            commandType: CommandType.StoredProcedure,
            transaction: _transaction
        );
    }
}
