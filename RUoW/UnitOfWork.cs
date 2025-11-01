using Microsoft.Data.SqlClient;
using RUoW.Interfaces;
using RUoW.Repos;

namespace HospitalApp
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly SqlConnection _connection;
        private SqlTransaction _transaction;

        public IPatientRepository Patients { get; }
        public IAppointmentRepository Appointments { get; }

        public UnitOfWork(string connectionString)
        {
            _connection = new SqlConnection(connectionString);
            _connection.Open();
            _connection.ChangeDatabase("Database2");
            _transaction = _connection.BeginTransaction();

            Patients = new PatientRepository(_connection, _transaction);
            Appointments = new AppointmentRepository(_connection, _transaction);
        }

        public async Task CommitAsync()
        {
            try
            {
                await _transaction.CommitAsync();
            }
            catch
            {
                await _transaction.RollbackAsync();
                throw;
            }
            finally
            {
                await _transaction.DisposeAsync();
                _transaction = (SqlTransaction)await _connection.BeginTransactionAsync();
            }
        }

        public async Task RollbackAsync()
        {
            try
            {
                await _transaction.RollbackAsync();
            }
            finally
            {
                await _transaction.DisposeAsync();
                _transaction = (SqlTransaction)await _connection.BeginTransactionAsync();
            }
        }

        public void Dispose()
        {
            _transaction?.Dispose();
            _connection?.Dispose();
        }
    }
}