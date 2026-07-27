# PCT Batch 1998-2002 · Silver Jubilee registration

Static registration form for the Pant College of Technology batch of 1998-2002 reunion, hosted on GitHub Pages.

The form collects six fields: name, college ID, branch, mobile, current city, email. Submissions post to a private Google Apps Script web app that validates entries against the batch roster and appends them to a private Google Sheet. The visitor is then handed a WhatsApp message carrying the full registration, addressed to the committee, as a second channel and a reachability check.

No roster data, credentials, or contact numbers live in this repository. The committee WhatsApp number stays in the private Apps Script; the page fetches the wa.me link from the backend at runtime, and the button does not render when the backend is unreachable.
