namespace RUoW.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IPatientRepository Patients { get; }
    IAppointmentRepository Appointments { get; }

    Task CommitAsync(); // Підтвердити транзакцію
    Task RollbackAsync(); // Відкотити транзакцію
}
