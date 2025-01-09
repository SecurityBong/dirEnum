**dirEnum**

The Most Reliable Directory Enumeration Tool
dirEnum is a powerful, lightweight, and reliable CLI-based directory enumeration tool written in Bash. It is designed to identify directories and files on web servers by brute-forcing paths from a wordlist. 

**Features**

Recursive Enumeration: Automatically enumerates subdirectories dynamically.
HTTP Status Filtering: Displays only relevant HTTP codes (200, 301, 302) and skips 400, 403, etc.
Content-Length Filtering: Filters out junk responses based on response size.
Error Logging: Logs errors and skipped responses into a separate file.
Threading: Supports multithreading for faster enumeration.
Dependency Management: Checks and installs missing dependencies automatically.

**Usage**

./dirEnum.sh

              dirEnum v5.1                 
      The Most Reliable Directory Enum     
           Author: securitybong            


[?] Please enter the target URL (e.g., http://example.com):

http://example.com

[?] Would you like to perform recursive enumeration? (y/n):

n

[?] Please provide the path to the wordlist (or press Enter to use the default):

[*] Using built-in default wordlist.

[?] How many threads would you like to use? (default: 10):

20

[?] Would you like to save results to a file? (y/n):

y

[?] Please specify the output file name:

output.txt

**Output**

[*] Starting enumeration on http://example.com with 20 threads...

http://example.com/admin (200, Size: 1.2 KB)

http://example.com/uploads (301, Size: 850 bytes)

http://example.com/js (302, Size: 1.1 KB)

[*] Enumeration completed.

[*] Results saved to output.txt
