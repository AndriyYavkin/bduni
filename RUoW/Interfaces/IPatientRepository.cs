using RUoW.Models;

namespace RUoW.Interfaces;

public interface IPatientRepository
{
    Task<IEnumerable<Patient>> GetActivePatientsAsync();
    Task SoftDeletePatientAsync(Guid patientId, Guid updatedByUserId);
}
