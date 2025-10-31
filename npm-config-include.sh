function banner3 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[3]}::${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function blue { println '\e[34m%s\e[0m' "$*"; }                                                                                    


function node_refresh {
# (
# warn node refresh disabled; return 1
node_version=${1:-20}
export NVM_HOME=$(pwd)/.nvm
export NVM_DIR=$(pwd)/.nvm
banner3 node_version $node_version, component: $(basename $(dirname $(pwd)))/$(basename $(pwd))

if [ ! -d $NVM_DIR ];then
    install_nvm;
fi
if [ -d $NVM_DIR ];then
    installnode;
    nodever $node_version;
fi
# )
}

function install_nvm() {
  NVM_DIR="${NVM_DIR:-$(pwd)/.nvm}"
  echo && blue "------------------ INSTALL NVM ------------------" && echo
  git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
  echo installing nvm @ $NVM_DIR
  # echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install --lts)
  echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install-latest-npm)
}

function installnode() {
  if [ ! -d $NVM_DIR ];then echo no NVM_DIR: $NVM_DIR && return 1;fi
  echo && blue "------------------ NODE VIA NVM ------------------" && echo
  green "Updating nvm:" && echo $(pushd $NVM_DIR && git pull && popd || popd)
  if  ! command -v nvm >/dev/null; then
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  fi
  nodever
}

function nodever() {
  if [ ! -z "$1" ]; then
    nvm install ${1} >/dev/null 2>&1 && nvm use ${_} > /dev/null 2>&1\
      && nvm alias default ${_} > /dev/null 2>&1; nodever; else
    yellow "INFORMATIONAL: Use nodever to install or switch node versions:" && echo -e "\tusage: nodever [ver]"
    blue "node: $(node -v)"
    blue "npm: $(npm -v)"
    blue "nvm: $(nvm -v)"
  fi
}

function getyarn() {
  echo && blue "------------------ YARN - NEEDS NVM ------------------" && echo
  if ! command -v yarn >/dev/null 2>&1; then grey "Getting yarn: " && npm install --global yarn >/dev/null; fi
}