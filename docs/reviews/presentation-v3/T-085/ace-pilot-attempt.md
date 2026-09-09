# ACE-Step live pilot attempt

**Result:** FAILED generation attempt; no audio returned or admitted. **Spend:** $0. **Scope:** one anonymous online instrumental pilot under the recovery continuation lease. Stable Audio's eligibility/host-applicability gate is unchanged.

The live endpoint accepted the request and returned event `c2d4f091cfc24d1ab69a68137095c8e2`. Retrieving that event returned exactly:

```text
event: error
data: null
```

There was no downloadable result, diagnostic explanation, explicit quota reset or login instruction. This does not establish whether the cause was authentication, remaining quota or an internal demo error. No second generation was submitted, and no restrictions were bypassed.

## What the live session established

- The official [Space status API](https://huggingface.co/api/spaces/ACE-Step/Ace-Step-v1.5) returned RUNNING/READY, Zero hardware, and running source revision `7403460e9b34972f760317b56048f6cb9d4a3a11`.
- The [live configuration](https://ace-step-ace-step-v1-5.hf.space/config) explicitly reported successful initialization of `acestep-v15-xl-turbo`, its VAE and Qwen3-Embedding-0.6B text encoder, a secondary original turbo model and the 1.7B LM. The selected model was XL turbo. Loaded weight commit/hash was not exposed; the Space commit is not a weight hash.
- The [public API schema](https://ace-step-ace-step-v1-5.hf.space/gradio_api/info) exposed `generation_wrapper` and FLAC output. The request used its documented parameter order, custom text-to-music mode, one 20-second sample, FLAC, seed 85001, 60 BPM, D minor, 4/4, instrumental lyrics, no reference/source audio, thinking off and automatic generation off. Exact prompt and all parameter values are retained in `ace-pilot-request-metadata.json` and `ace-pilot-request.json`.
- Access used ordinary anonymous HTTPS requests, with no Authorization header, saved browser cookies, account or prepaid balance. The previously checked [ZeroGPU terms](https://huggingface.co/docs/hub/spaces-zerogpu) establish a free anonymous tier. Actual remaining GPU quota was not exposed by these metadata endpoints; the one request tested admission and failed before returning an asset. No chargeable identity or payment route was supplied.
- Before submission, downloaded snapshots retained the [XL model card](https://huggingface.co/ACE-Step/acestep-v15-xl-turbo), its explicit commercial music permission, the Space's MIT license, Hugging Face service terms and ZeroGPU documentation. This supersedes the preparation report's lack of full local snapshots for this route. It does not create source acceptance without an actual output.

## Access and commands

The computer-use skill was read. `cua.createBrowserTab("iab", ..., {visible:false})` reported that iab was unavailable; `cua.getState()` returned no apps or browsers. Thus no live browser interaction could be performed. The official Gradio API was used according to its [primary curl guide](https://gradio.app/guides/querying-gradio-apps-with-curl). Network commands required sandbox escalation and were approved by automatic review. No escalation was rejected.

Read-only GET requests used PowerShell `Invoke-WebRequest -UseBasicParsing -TimeoutSec 30 -OutFile <evidence path>` for config, API info, Space status, model card, pinned MIT license, service terms and quota documentation. `-OutFile` preserves response bytes. An initial `.Content` copy produced misdecoded characters; it was replaced by the exact-byte config GET before request preparation. Python's standard `json` module parsed the schema and wrote the request; no third-party software was installed or executed.

The actual generation and retrieval commands were:

```powershell
$pilotBody = Get-Content -Raw 'docs/reviews/presentation-v3/T-085/ace-pilot-request.json'
Invoke-WebRequest -UseBasicParsing -TimeoutSec 30 -Method Post -ContentType 'application/json' -Body $pilotBody 'https://ace-step-ace-step-v1-5.hf.space/gradio_api/call/generation_wrapper' -OutFile 'docs/reviews/presentation-v3/T-085/ace-pilot-event.json'
Invoke-WebRequest -UseBasicParsing -TimeoutSec 55 'https://ace-step-ace-step-v1-5.hf.space/gradio_api/call/generation_wrapper/c2d4f091cfc24d1ab69a68137095c8e2' -OutFile 'docs/reviews/presentation-v3/T-085/ace-pilot-result.sse'
```

## Gate disposition

| Gate | Result |
|---|---|
| Live host access and initialized model identity | PASS; weight revision not exposed |
| Named model's commercial output permission and local terms evidence | PASS |
| No paid session, account creation, automatic batches or local GPU | PASS |
| Actual successful free generation/download | FAIL for this attempt; unexplained API error |
| Download metadata, original audio hash and audible review | NOT AVAILABLE; no asset returned |
| Runtime/mix/native tests | NOT RUN; outside pilot lease |

The next useful action is an official demo attempt in an available connected browser, where a quota or authentication error may be visible, or a later explicitly leased retry after the host has recovered. Do not infer a need to purchase anything. The registered-account route and paid credits were not used. Evidence is hashed by `pilot-evidence-manifest.json`; no shipping audio directory was populated.
