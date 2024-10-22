public with sharing class NewAppointmentController {
    
    // Search Patients by Email or Name
    @AuraEnabled(cacheable=true)
    public static List<PatientOption> searchPatients(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<PatientOption>();
        }

        List<Patient__c> patients = [
            SELECT Id, Name, Email__c
            FROM Patient__c
            WHERE Email__c LIKE :('%' + searchTerm + '%') OR Name LIKE :('%' + searchTerm + '%')
            LIMIT 10
        ];

        List<PatientOption> options = new List<PatientOption>();
        for (Patient__c patient : patients) {
            options.add(new PatientOption(patient.Id, patient.Name + ' (' + patient.Email__c + ')'));
        }
        return options;
    }

    // Search Doctors by Name
    @AuraEnabled(cacheable=true)
    public static List<DoctorOption> searchDoctors(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<DoctorOption>();
        }

        List<Doctor__c> doctors = [
            SELECT Id, Name
            FROM Doctor__c
            WHERE Name LIKE :('%' + searchTerm + '%')
            LIMIT 10
        ];

        List<DoctorOption> options = new List<DoctorOption>();
        for (Doctor__c doctor : doctors) {
            options.add(new DoctorOption(doctor.Id, doctor.Name));
        }
        return options;
    }

    // Fetch Services for Service Picklist
    @AuraEnabled(cacheable=true)
    public static List<ServiceOption> getServices() {
        List<Service__c> services = [
            SELECT Id, Name
            FROM Service__c
            ORDER BY Name ASC
            LIMIT 100
        ];

        List<ServiceOption> options = new List<ServiceOption>();
        for (Service__c service : services) {
            options.add(new ServiceOption(service.Id, service.Name));
        }
        return options;
    }

    // Fetch Reasons for Visit Picklist
    @AuraEnabled(cacheable=true)
    public static List<ReasonOption> getReasonsForVisit() {
        // Assuming you have a custom metadata or a custom object to store reasons
        // For simplicity, let's define a static list
        List<ReasonOption> reasons = new List<ReasonOption>{
            new ReasonOption('General Consultation'),
            new ReasonOption('Follow-up'),
            new ReasonOption('Emergency'),
            new ReasonOption('Routine Checkup'),
            new ReasonOption('Other')
        };
        return reasons;
    }

    // Get Available Time Slots
    @AuraEnabled(cacheable=true)
    public static List<TimeSlotOption> getAvailableTimeSlots(Id doctorId, Date appointmentDate) {
        List<TimeSlotOption> timeSlots = new List<TimeSlotOption>();

        // Define working hours (e.g., 9 AM to 5 PM GMT)
        Time startWorkingTime = Time.newInstance(9, 0, 0, 0);
        Time endWorkingTime = Time.newInstance(17, 0, 0, 0);
        Integer slotDurationMinutes = 30;

        // Convert appointmentDate to Datetime in GMT
        Datetime startOfDay = Datetime.newInstanceGmt(appointmentDate, startWorkingTime);
        Datetime endOfDay = Datetime.newInstanceGmt(appointmentDate, endWorkingTime);

        // Fetch existing appointments for the doctor on the given date
        List<Appointment__c> existingAppointments = [
            SELECT Appointment_Date__c
            FROM Appointment__c
            WHERE Doctor__c = :doctorId
              AND Appointment_Date__c >= :startOfDay
              AND Appointment_Date__c < :endOfDay
              AND Status__c != 'Cancelled'
        ];

        Set<Datetime> bookedSlots = new Set<Datetime>();
        for (Appointment__c app : existingAppointments) {
            bookedSlots.add(app.Appointment_Date__c);
        }

        // Generate available time slots
        Datetime currentSlot = startOfDay;
        while (currentSlot < endOfDay) {
            if (!bookedSlots.contains(currentSlot)) {
                String label = formatDatetime(currentSlot);
                String value = String.valueOf(currentSlot); // ISO format
                timeSlots.add(new TimeSlotOption(label, value));
            }
            currentSlot = currentSlot.addMinutes(slotDurationMinutes);
        }

        return timeSlots;
    }

    private static String formatDatetime(Datetime dt) {
        return dt.format('h:mm a'); // e.g., "2:30 PM"
    }

    // Create Appointment
    @AuraEnabled
    public static void createAppointment(String patientId, Id doctorId, String appointmentDateTimeStr, String serviceId, String reasonForVisit) {
        // Input Validation
        if (String.isBlank(patientId) || doctorId == null || String.isBlank(appointmentDateTimeStr) || String.isBlank(serviceId) || String.isBlank(reasonForVisit)) {
            throw new AuraHandledException('All required fields must be filled.');
        }

        // Parse appointmentDateTimeStr to Datetime in GMT
        Datetime appointmentDateTime;
        try {
            appointmentDateTime = Datetime.valueOfGmt(appointmentDateTimeStr);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid date and time format.');
        }

        // Check for double booking
        Integer existingAppointments = [
            SELECT COUNT()
            FROM Appointment__c
            WHERE Doctor__c = :doctorId
              AND Appointment_Date__c = :appointmentDateTime
              AND Status__c != 'Cancelled'
        ];

        if (existingAppointments > 0) {
            throw new AuraHandledException('The selected time slot is no longer available.');
        }

        // Fetch Service Name to set as Appointment Name
        Service__c selectedService = [
            SELECT Name
            FROM Service__c
            WHERE Id = :serviceId
            LIMIT 1
        ];

        if (selectedService == null) {
            throw new AuraHandledException('Selected service not found.');
        }

        // Create Appointment
        Appointment__c appointment = new Appointment__c();
        appointment.Name = selectedService.Name; // Set Name to Service Name
        appointment.Patient__c = patientId;
        appointment.Doctor__c = doctorId;
        appointment.Appointment_Date__c = appointmentDateTime;
        appointment.Service__c = serviceId;
        appointment.Reason_For_Visit__c = reasonForVisit;
        appointment.Status__c = 'Scheduled';

        insert appointment;
    }

    // Data Transfer Classes
    public class DoctorOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public DoctorOption(Id id, String name) {
            this.label = name;
            this.value = String.valueOf(id);
        }
    }

    public class PatientOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PatientOption(Id id, String name) {
            this.label = name;
            this.value = String.valueOf(id);
        }
    }

    public class ServiceOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public ServiceOption(Id id, String name) {
            this.label = name;
            this.value = String.valueOf(id);
        }
    }

    public class TimeSlotOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public TimeSlotOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ReasonOption {
        @AuraEnabled public String label { get; set; }

        public ReasonOption(String label) {
            this.label = label;
        }
    }
}
