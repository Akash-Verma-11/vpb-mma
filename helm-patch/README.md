# Patch: helm/vpb-mma/templates/service.yaml

Replace your existing `helm/vpb-mma/templates/service.yaml` (from Chapter 4)
with this file. The only change: the port now has `name: http`.

Why: Prometheus Operator's ServiceMonitor (Chapter 6) references a Service
port **by name**, not by number. Without this, the ServiceMonitors in this
chapter won't match anything.

After replacing the file:
```bash
helm upgrade vpb-mma helm/vpb-mma -n vpb-mma --reuse-values
```
