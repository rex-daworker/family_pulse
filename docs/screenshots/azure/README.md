# Azure and CI/CD evidence

Captured 24–26 November 2026 while building the multi-day free-time search
and the deployment pipeline.

| File | What it shows and why it matters |
|---|---|
| `01_region_policy_allowlist.png` | The subscription's **Allowed resource deployment regions** policy: `belgiumcentral`, `norwayeast`, `austriaeast`, `switzerlandnorth`, `italynorth`. Azure Static Web Apps exists in none of them, which is why every attempt to create one failed with `RequestDisallowedByAzure` regardless of the region chosen in the portal. The portal's dropdown lists where the service runs globally, not where this subscription may deploy — the two never reconcile until Create is pressed |
| `02_function_deploy_success.png` | `func azure functionapp publish` completing: the `freeSlots` HTTP trigger live in Norway East, host reporting `Running` on the v4 runtime |
| `03_cors_and_401_auth_check.png` | CORS restricted to `https://family-pulse-sznzoj.web.app` only, and two anonymous requests rejected with `HTTP 401`. The 401 is the point — Firebase token validation runs before any Firestore access |
| `04_demo_family_seeded.png` | The seed script creating three accounts, one family and 48 events across 14 days, so a reviewer finds a populated calendar rather than an empty one |
| `05_ci_caught_environment_drift.png` | The pipeline failing on 31 deprecation infos that `flutter analyze` passed locally. The runner had installed a newer Flutter than the development machine. This is the case for pinning a toolchain: an unpinned build is not reproducible, and CI caught a class of problem a laptop structurally cannot |
| `06_pipeline_green.png` | Both jobs passing — Azure Functions unit tests, then Flutter build and Firebase Hosting deploy — in 2m 40s |

The failure in `05` is deliberately kept. A pipeline that has never failed has
not yet proved it does anything.
