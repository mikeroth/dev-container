## Mike's Dev Container
Leave your local alone and work here

# Assumptions
* You have `Oh My ZSH` installed
* You have your github ssh key in ~/.ssh

# dev
This is just a simple bash script to start the container.

`chmod +x dev` and move to `/usr/local/bin/dev`
then run `dev` to enter the container.

In iTerm2, under Preferences > Profiles > General
there's a "Command" section. Choose "Login Shell" from dropdown, and
set "Send text at start: `dev`", dev will run in every new iTerm2 tab.

# Steps to Build Container
`docker build --squash --pull --rm -f "Dockerfile" -t dev:v0.0.1 "."`

# Create alias on mac
In your work directory create a file called dev.txt
make sure it looks similar to this with your name email.

Ex:
```bash
export user_first_last=Michael Roth
export user_email=mikeroth.sd@gmail.com
eval `ssh-agent -s`
ssh-add ~/.ssh/id_ed25519
```
Create your alias
`echo "alias ws='cat ~/work/dev.txt|pbcopy'" >> ~/.zshrc`

Now run `ws && dev`
When the container starts just paste what is in your clipboard and press enter.

# Send AWS creds to your mac
`printenv | grep AWS | sed "1 s/^/[default]\n/" > ~/.aws/credentials`

# Cheats

# List cheats
`cheat -l`
# List personal cheats
`cheat -l -p personal`
# Learn more about how we run vault
`cheat k`
# List useful kubectl log commands
`cheat k-logs`
# List useful krew plugins
`cheat krew`
# Useful aws commands
`cheat aws`

# tldr (More cheetsheets)
Ex: 
`tldr netstat`
