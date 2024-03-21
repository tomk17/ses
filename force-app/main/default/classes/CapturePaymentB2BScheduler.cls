global class CapturePaymentB2BScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        CapturePaymentB2BBatch batch = new CapturePaymentB2BBatch();
        Database.executeBatch(batch, 100);
    }
    
}