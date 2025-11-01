namespace RUoW.Models;

public class DoctorScheduleView
{
    public Guid AppointmentId { get; set; }
    public DateTime AppointmentDate { get; set; }
    public string Status { get; set; }
    public string DoctorFirstName { get; set; }
    public string DoctorLastName { get; set; }
    public string PatientFirstName { get; set; }
    public string PatientLastName { get; set; }
}
