public abstract class UHT_CDC_Handler {

    public class CDCContext {
        public String entityName;
        public String changeType;
        public Id recordId;

        // ✅ Add these
        public Datetime commitTimestamp;
        public String commitUserId;
        public String commitNumber;

        public Map<String, Object> rawPayload;

        public CDCContext(Map<String, Object> payload) {
            rawPayload = payload;

            Object hdr = payload.get('ChangeEventHeader');
            if (hdr != null) {
                Map<String, Object> header =
                    (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(hdr));

                entityName = (String) header.get('entityName');
                changeType = (String) header.get('changeType');

                // recordIds
                Object rid = header.get('recordIds');
                if (rid instanceof List<Object> && !((List<Object>)rid).isEmpty()) {
                    recordId = (Id) ((List<Object>)rid)[0];
                }

                // ✅ commitTimestamp (epoch millis) → Datetime
                Object ts = header.get('commitTimestamp');
                if (ts != null) {
                    // commitTimestamp comes through as epoch millis
                    Long epochMillis = (ts instanceof Long)
                        ? (Long) ts
                        : Long.valueOf(String.valueOf(ts));
                    commitTimestamp = Datetime.newInstance(epochMillis);
                }

                // ✅ commitUser (Id string)
                Object cu = header.get('commitUser');
                if (cu != null) {
                    commitUserId = String.valueOf(cu);
                }

                // ✅ commitNumber (large numeric, store as string)
                Object cn = header.get('commitNumber');
                if (cn != null) {
                    commitNumber = String.valueOf(cn);
                }
            }
        }
    }

    public void handle(CDCContext ctx) {
        if (ctx == null || ctx.changeType == null) {
            return;
        }

        if (ctx.changeType == 'CREATE') {
            handleCreate(ctx);
        } else if (ctx.changeType == 'UPDATE') {
            handleUpdate(ctx);
        } else if (ctx.changeType == 'DELETE') {
            handleDelete(ctx);
        } else if (ctx.changeType == 'UNDELETE') {
            handleUndelete(ctx);
        } else {
            handleOther(ctx);
        }
    }

    protected virtual void handleCreate(CDCContext ctx) {}
    protected virtual void handleUpdate(CDCContext ctx) {}
    protected virtual void handleDelete(CDCContext ctx) {}
    protected virtual void handleUndelete(CDCContext ctx) {}
    protected virtual void handleOther(CDCContext ctx) {}
}
