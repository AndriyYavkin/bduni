using RUoW.Interfaces;
using System.Globalization;

namespace HospitalApp;

class Program
{
    private const string ConnectionString =
        "Data Source=(localdb)\\MSSQLLocalDB;Initial Catalog=Database2;Integrated Security=True;Encrypt=True;Trust Server Certificate=True;";
    private static Guid CreatedBy = Guid.Parse("00000000-0000-0000-0000-000000000001");

    static async Task Main(string[] args)
    {
        bool isRunning = true;
        while (isRunning)
        {
            ShowMenu();
            Console.Write("Enter your choice: ");
            string choice = Console.ReadLine();
            Console.Clear();

            try
            {
                using (var uow = new UnitOfWork(ConnectionString))
                {
                    isRunning = await ProcessChoice(uow, choice);

                    if (choice != "6" && choice != "7")
                    {
                        await uow.CommitAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                ShowError(ex.Message);
            }

            if (isRunning)
            {
                Console.WriteLine("\nPress Enter to return to the menu...");
                Console.ReadLine();
                Console.Clear();
            }
        }
    }

    private static void ShowMenu()
    {
        Console.WriteLine("--- Hospital Management Console ---");
        Console.WriteLine("1. List all active patients (Uses View)");
        Console.WriteLine("2. List today's schedule (Uses View)");
        Console.WriteLine("3. Check doctor availability (Uses Function)");
        Console.WriteLine("4. Create new appointment (Uses SP)");
        Console.WriteLine("5. Soft-delete a patient (Uses SP)");
        Console.WriteLine("6. Exit");
        Console.WriteLine("-----------------------------------");
    }

    private static async Task<bool> ProcessChoice(IUnitOfWork uow, string choice)
    {
        switch (choice)
        {
            case "1":
                await ListActivePatients(uow);
                break;
            case "2":
                await ListTodaysSchedule(uow);
                break;
            case "3":
                await CheckDoctorAvailability(uow);
                break;
            case "4":
                await CreateAppointment(uow);
                break;
            case "5":
                await SoftDeletePatient(uow);
                break;
            case "6":
                return false;
            default:
                ShowError("Invalid choice. Please try again.");
                break;
        }
        return true;
    }

    private static async Task ListActivePatients(IUnitOfWork uow)
    {
        Console.WriteLine("Active Patients");
        var patients = await uow.Patients.GetActivePatientsAsync();
        int count = 0;
        foreach (var p in patients)
        {
            Console.WriteLine($"  - ID: {p.Id}");
            Console.WriteLine($"    Name: {p.FirstName} {p.LastName}");
            Console.WriteLine($"    Phone: {p.PhoneNumber}\n");
            count++;
        }
        Console.WriteLine($"Total active patients: {count}");
    }

    private static async Task ListTodaysSchedule(IUnitOfWork uow)
    {
        Console.WriteLine("Today's Schedule");
        var schedule = await uow.Appointments.GetTodaysScheduleAsync();
        int count = 0;
        foreach (var s in schedule)
        {
            Console.WriteLine($"    Time: {s.AppointmentDate.ToShortTimeString()} ({s.Status})");
            Console.WriteLine($"    Doctor: Dr. {s.DoctorLastName}");
            Console.WriteLine($"    Patient: {s.PatientFirstName} {s.PatientLastName}\n");
            count++;
        }
        Console.WriteLine($"Total appointments today: {count}");
    }

    private static async Task CheckDoctorAvailability(IUnitOfWork uow)
    {
        Console.WriteLine("Check Doctor Availability");
        Guid doctorId = ReadGuid("Enter Doctor ID");
        DateTime checkTime = ReadDateTime("Enter date and time");

        bool isAvailable = await uow.Appointments.IsDoctorAvailableAsync(doctorId, checkTime);

        Console.ForegroundColor = isAvailable ? ConsoleColor.Green : ConsoleColor.Red;
        Console.WriteLine($"Result: Doctor is {(isAvailable ? "AVAILABLE" : "NOT AVAILABLE")} at {checkTime}.");
        Console.ResetColor();
    }

    private static async Task CreateAppointment(IUnitOfWork uow)
    {
        Console.WriteLine("Create New Appointment");
        Guid patientId = ReadGuid("Enter Patient ID");
        Guid doctorId = ReadGuid("Enter Doctor ID");
        DateTime appTime = ReadDateTime("Enter appointment date and time");

        await uow.Appointments.CreateAppointmentAsync(patientId, doctorId, appTime, CreatedBy);

        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("Successfully created new appointment. (Will be saved on commit)");
        Console.ResetColor();
    }

    private static async Task SoftDeletePatient(IUnitOfWork uow)
    {
        Console.WriteLine("Soft Delete Patient");
        Guid patientId = ReadGuid("Enter Patient ID to delete");

        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.Write($"ARE YOU SURE you want to delete patient {patientId}? (y/n): ");
        Console.ResetColor();
        string confirm = Console.ReadLine();

        if (confirm.ToLower() == "y")
        {
            await uow.Patients.SoftDeletePatientAsync(patientId, CreatedBy);
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"Patient {patientId} marked as deleted. (Will be saved on commit)");
            Console.ResetColor();
        }
        else
        {
            Console.WriteLine("Operation cancelled.");
        }
    }

    private static void ShowError(string message)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine($"ERROR: {message}");
        Console.ResetColor();
    }

    private static Guid ReadGuid(string prompt)
    {
        while (true)
        {
            Console.WriteLine(prompt);
            string input = Console.ReadLine();
            if (Guid.TryParse(input, out Guid result))
            {
                return result;
            }
            ShowError("Invalid GUID format. Please try again.");
        }
    }

    private static DateTime ReadDateTime(string prompt)
    {
        while (true)
        {
            Console.WriteLine(prompt);
            string input = Console.ReadLine();
            if (DateTime.TryParse(input, CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime result))
            {
                return result;
            }
            ShowError("Invalid DateTime format. Use 'YYYY-MM-DD HH:MM'. Please try again.");
        }
    }
}