trigger MaintenanceRequest on Case(before update, after update) {
    // ToDo: Call MaintenanceRequestHelper.updateWorkOrders
    MaintenanceRequestHelper helper = new MaintenanceRequestHelper();

    if (Trigger.isBefore && Trigger.isUpdate) {
        System.debug('Before Upd');
        helper.updateWorkOrders(Trigger.New);
    }
}
