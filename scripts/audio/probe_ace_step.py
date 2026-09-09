"""One bounded, anonymous request through the official Gradio client.

Requires gradio_client in the supplied temporary package directory. No token is
loaded, no browser cookies are supplied, and output files are not auto-downloaded.
The request document is reviewed and saved before this script is invoked.
"""
import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--client-directory', required=True)
    parser.add_argument('--request', required=True)
    parser.add_argument('--result', required=True)
    args = parser.parse_args()
    os.environ['GRADIO_ANALYTICS_ENABLED'] = 'False'
    sys.path.insert(0, args.client_directory)
    from gradio_client import Client
    from gradio_client import __version__

    request = json.loads(Path(args.request).read_text(encoding='utf-8'))
    values = request['data']
    assert values[16] == 1 and values[48] is False
    assert values[15] <= 30 and values[30] == 'flac'
    assert values[14] is None and values[17] is None
    result = {'started_utc': datetime.now(timezone.utc).isoformat(),
              'client_version': __version__, 'anonymous': True,
              'attempt_count': 1, 'automatic_generation': False,
              'request_file': args.request, 'spend_usd': 0}
    client = None
    job = None
    try:
        client = Client('https://ace-step-ace-step-v1-5.hf.space', token=False,
                        max_workers=2, verbose=False, download_files=False,
                        analytics_enabled=False, httpx_kwargs={'timeout': 45})
        assert not any('authorization' in k.lower() for k in client.headers)
        assert not client.cookies
        job = client.submit(*values, api_name='/generation_wrapper')
        result['output'] = job.result(timeout=55)
        result['status'] = 'completed'
    except Exception as exc:
        result['status'] = 'failed'
        result['error_type'] = type(exc).__name__
        result['error'] = str(exc)
        if job is not None:
            result['last_job_status'] = str(job.status())
            result['partial_outputs'] = job.outputs()
            result['cancel_requested'] = job.cancel()
    finally:
        if client is not None:
            client.close()
    result['finished_utc'] = datetime.now(timezone.utc).isoformat()
    Path(args.result).write_text(json.dumps(result, indent=2, default=str) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True, default=str))


if __name__ == '__main__':
    main()
