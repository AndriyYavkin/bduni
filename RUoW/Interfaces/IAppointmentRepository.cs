using RUoW.Models;

namespace RUoW.Interfaces;

public interface IAppointmentRepository
{
    Task<IEnumerable<DoctorScheduleView>> GetTodaysScheduleAsync();

    Task<bool> IsDoctorAvailableAsync(Guid doctorId, DateTime checkTime);

    Task CreateAppointmentAsync(Guid patientId, Guid doctorId, DateTime appDate, Guid createdByUserId);

    Task UpdateAppointmentStatusAsync(Guid appointmentId, string newStatus, Guid updatedByUserId);
}
