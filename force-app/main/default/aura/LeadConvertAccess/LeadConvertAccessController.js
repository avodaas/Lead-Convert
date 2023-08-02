({
    doInit : function(component, event, helper) {
        var PageRef = component.get("v.pageReference");
        var recordId = PageRef.state.c__recordId;
        component.set("v.recordId", recordId);
    },
    onPageReferenceChanged: function(component, event, helper) {
        const PageRef = component.get("v.pageReference");
        var recordId = PageRef.state.c__recordId;
        component.set("v.recordId", recordId);
        $A.get('e.force:refreshView').fire();
    }
})