# CertificateTransparencyTools
Tools to work with Certificate Transparency Lists (per RFC 6962) in Ruby. Parses the binary Merkle Structures and has code to
parse out relevant certificate data from the structures. Working to output the same JSON format as Certstream (https://certstream.calidog.io/).
Will eventually also have code to download the entirety of logs for historical data analytics purposes.

This code is largely inspired by the Axeman tool at https://github.com/CaliDog/Axeman (thanks!)

### Caveats/Known Issues
* JRuby doesn't seem to work due to bouncycastle (the JRuby OpenSSL library) not properly parsing some certificates
* There is an encoding issue that I need to fix. This causes a small percentage of batches to fail
* Currently only downloads over SSL. This is required for some logs but makes others potentially slower if they support HTTP
* Still too slow for any meaningful batch downloading
* Writes JSON files with one JSON string per line
* Only supports one output writer, but this is an interface that can be implemented for any sort of writer you want

### References
* https://tools.ietf.org/html/rfc6962


