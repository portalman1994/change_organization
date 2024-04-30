# Script that changes organization instances
## Note: The script must be run within the scripts directory of complaint manager

Download script
```bash
curl -O https://raw.githubusercontent.com/portalman1994/change_organization/main/change_organization.zsh
```

Make script executable
```bash
chmod +x change_organization.zsh
```
Run script
```bash
./change_organization.zsh
```
## How do I know my path to instance files?
- Open a new terminal. Make sure to have the script running.
- Change directory to the instance-files sub directory using `cd`
- Use the following command to copy your path
```bash
pwd | pbcopy
```
