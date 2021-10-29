global class WarehouseSyncSchedule implements Schedulable {
    // implement scheduled code here
    global void execute(SchedulableContext sc) {
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
    }
}
