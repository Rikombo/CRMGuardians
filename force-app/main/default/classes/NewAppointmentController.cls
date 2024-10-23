public with sharing class NewAppointmentController {
    
    // Wrapper class for Patient Options
    public class PatientOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PatientOption(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }

    // Wrapper class for Doctor Options
    public class DoctorOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public DoctorOption(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }

    // Wrapper class for Service Options
    public class ServiceOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public ServiceOption(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }

    // Wrapper class for Reason Options
    public class ReasonOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public ReasonOption(String label) {
            this.label = label;
            this.value = label; // Set value same as label
        }
    }

    // Wrapper class for Time Slot Options
    public class TimeSlotOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public TimeSlotOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    // Search Patients by Email or Name
    @AuraEnabled(cacheable=true)
    public static List<PatientOption> searchPatients(String searchTerm) {
        List<PatientOption> options = new List<PatientOption>();
        
        if (String.isBlank(searchTerm)) {
            return options;
        }

        List<Patient__c> patients = [
            SELECT Id, Name, Email__c
            FROM Patient__c
            WHERE Email__c LIKE :('%' + searchTerm + '%') OR Name LIKE :('%' + searchTerm + '%')
            LIMIT 10
        ];

        for (Patient__c patient : patients) {
            String label = patient.Name + ' (' + patient.Email__c + ')';
            options.add(new PatientOption(patient.Id, label));
        }

        return options;
    }

    // Search Doctors by Name
    @AuraEnabled(cacheable=true)
    public static List<DoctorOption> searchDoctors(String searchTerm) {
        List<DoctorOption> options = new List<DoctorOption>();
        
        if (String.isBlank(searchTerm)) {
            return options;
        }

        List<Doctor__c> doctors = [
            SELECT Id, Name
            FROM Doctor__c
            WHERE Name LIKE :('%' + searchTerm + '%')
            LIMIT 10
        ];

        for (Doctor__c doctor : doctors) {
            options.add(new DoctorOption(doctor.Id, doctor.Name));
        }

        return options;
    }

    // Fetch Services for Service Picklist
    @AuraEnabled(cacheable=true)
    public static List<ServiceOption> getServices() {
        List<ServiceOption> options = new List<ServiceOption>();
        
        List<Service__c> services = [
            SELECT Id, Name
            FROM Service__c
            ORDER BY Name ASC
            LIMIT 100
        ];

        for (Service__c service : services) {
            options.add(new ServiceOption(service.Id, service.Name));
        }

        return options;
    }

    // Fetch Reasons for Visit Picklist
    @AuraEnabled(cacheable=true)
    public static List<ReasonOption> getReasonsForVisit() {
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

        // Define working hours (9 AM to 5 PM GMT)
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

    // Check Appointment Availability
    @AuraEnabled
    public static Boolean checkAppointmentAvailability(String doctorId, String appointmentDateTimeStr) {
        // Parse the appointment date and time
        Datetime appointmentDateTime;
        try {
            appointmentDateTime = Datetime.valueOfGmt(appointmentDateTimeStr);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid date and time format.');
        }

        // Define the start and end time for the appointment slot (assuming appointments are 1 hour)
        Datetime appointmentStart = appointmentDateTime;
        Datetime appointmentEnd = appointmentStart.addHours(1);

        // Query existing appointments for the doctor that overlap with the desired time slot
        Integer overlappingAppointments = [
            SELECT COUNT()
            FROM Appointment__c
            WHERE Doctor__c = :doctorId
              AND Appointment_Date__c < :appointmentEnd
              AND Appointment_Date__c >= :appointmentStart
              AND Status__c != 'Cancelled'
        ];

        return overlappingAppointments == 0;
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

        // Work Hours Validation: 9 AM to 5 PM GMT
        Integer appointmentHour = appointmentDateTime.hour();

        if (appointmentHour < 9 || appointmentHour >= 17) {
            throw new AuraHandledException('Appointments can only be scheduled between 9 AM and 5 PM.');
        }

        // Check for double booking using the checkAppointmentAvailability method
        Boolean isAvailable = checkAppointmentAvailability(doctorId, appointmentDateTimeStr);
        if (!isAvailable) {
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

        try {
            insert appointment;
        } catch (DmlException e) {
            throw new AuraHandledException('An error occurred while creating the appointment: ' + e.getMessage());
        }
    }
}
