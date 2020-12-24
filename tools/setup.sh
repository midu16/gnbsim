#!/bin/bash
#--------------------------------------------------------------------------------------------------------------
black='\E[30m'
red='\E[31m'
green='\E[32m'
yellow='\E[33m'
blue='\E[1;34m'
magenta='\E[35m'
cyan='\E[36m'
white='\E[37m'
reset_color='\E[00m'
COLORIZE=1

cecho() {
    local default_msg="No Message."
    message=${1:-$default_msg}
    color=${2:-$green}
    [ "$COLORIZE" = "1" ] && message="$color$message$reset_color"
    echo -e "$message"
    return

}

echo_error()    {   cecho "$*" $red          ;}
echo_fatal()    {   cecho "$*" $red; exit -1 ;}
echo_warn()     {   cecho "$*" $yellow       ;}
echo_success()  {   cecho "$*" $green        ;}
echo_info()     {   cecho "$*" $blue         ;}

#--------------------------------------------------------------------------------------------------------------
TMP_DIR=/tmp
ARCH=`uname -m`
GO_VERSION=`go version`
OS_TYPE=$(awk '{ print $1 }' /proc/version)
SUDO='sudo -E'
ORIGIN_PATH=$PWD

# determining the os_distribution
os=$(grep "^ID=" /etc/os-release | sed "s/ID=//" | sed "s/\"//g")
os_release=$(grep "^VERSION_ID=" /etc/os-release | sed "s/VERSION_ID=//" | sed "s/\"//g")
os_distribution=$os$os_release
echo_info "Detected OS Distribution:    $os_distribution"

case "$os" in
    fedora)     os_base="fedora"; os_pm="dnf";      os_make="make" ;;
    rhel)       os_base="fedora"; os_pm="yum";      os_make="make" ;;
    centos)     os_base="fedora"; os_pm="yum";      os_make="make" ;;
    debian)     os_base="debian"; os_pm="apt-get";  os_make="make" ;;
    ubuntu)     os_base="debian"; os_pm="apt";      os_make="make" ;;
    rasbian)    os_base="debian"; os_pm="apt-get";  os_make="make" ;;
esac

check_supported_os_dist() {
    case "$os_dist" in
        "rasbian10")   return 1 ;;
        "debian10")    return 0 ;;
        "debian9")     return 0 ;;
        "ubuntu20.04") return 0 ;;
        "ubuntu19.04") return 0 ;;
        "ubuntu18.04") return 0 ;;
	    "ubuntu17.10") return 0 ;;
        "ubuntu17.04") return 0 ;;
        "ubuntu16.04") return 0 ;;
        "fedora24")    return 1 ;;
        "rhel7")       return 1 ;;
        "centos7")     return 1 ;;
    esac
    return 1
}
#--------------------------------------------------------------------------------------------------------------
#Installing additional tools
install_required_packages() {

    if ! check_supported_os_dist; then
        echo_error "Your distribution $os_dist kernel requires to be re-compile to support gnbsim project !"
        exit 1
    fi
    
    $SUDO $os_pm  update -y
	$SUDO $os_pm install -y \
	      virt-what \
          build-essential \
	      npm \
	      curl \
	      jq \ 
          git \ 
          gcc \ 
          cmake \ 
          autoconf \ 
          libtool \ 
          pkg-config \ 
          libmnl-dev \
          libyaml-dev \
          linux-headers-$(uname -r)
       
}
#--------------------------------------------------------------------------------------------------------------
#After the golang is installed then the gtp kernel should be installed 
#until the moment the support is offered just for the Ubuntu and Debian os_base
install_golang_kernel_libraries() {
    if ! check_supported_os_dist; then
        echo_error "Your distribution $os_dist kernel requires to be re-compile to support gnbsim project !"
        exit 1
    else
        echo_info "For your distribution $os_dist will be installed the go-gtp kernel module!"
        for url in "https://github.com/wmnsk/go-gtp/archive/v0.7.15.zip"
        do
            wget -O $TMP_DIR/go-gtp.zip $url
        done
        unzip $TMP_DIR/go-gtp.zip
        cd $TMP_DIR/go-gtp
        go mod tidy
        go build
        cd $ORIGIN_PATH
    fi
}
check_golang_kernel_libraries_installation() {
#find /lib/modules/`uname -r` -name gtp.ko  
    if find /lib/modules/`uname -r` -name gtp.ko; then
        echo ""
        echo_success "The go gtp module was scusesfully installed!"
    else
        echo_fatal "The installation failed! Please report the issue!"
    fi
}
#--------------------------------------------------------------------------------------------------------------
# Making sure that last golang version available is installed
install_golang_package() {
    if [ $OS_TYPE == "Linux" ]; then
        # waits for the url to finish
        if [ -d /usr/local/go ]; then 
            echo ""
            echo "...... [ Found an older: $GO_VERSION ]"
        else
            echo "Installing.."
            if "$ARCH" == "armv"* ;
            then
                for url in "https://golang.org/dl/go1.15.6.linux-armv6l.tar.gz"
                do
                    wget -P $TMP_DIR $url
                done
                sudo tar -C /usr/local -zxvf go1.*
                mkdir -p ~/go/{bin,pkg,src}
            else "$ARCH" == "x86_64";
                for url in "https://golang.org/dl/go1.15.6.linux-amd64.tar.gz"
                do
                    wget -P $TMP_DIR $url
                done
                sudo tar -C /usr/local -zxvf go1.*
                mkdir -p ~/go/{bin,pkg,src}
            fi
        fi
        # The following assume that your shell is bash
        if grep -xq "export GOROOT=/usr/local/go" ~/.bashrc
        then
            # code if found
            echo ""
        else
            # code if not found
            echo 'export GOPATH=$HOME/go' >> ~/.bashrc
            echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
            echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ~/.bashrc
        fi
        source ~/.bashrc
    else
        echo "Only for LINUX distribution!"
    fi
}
#--------------------------------------------------------------------------------------------------------------
function main() {
    install_required_packages
    install_golang_package
	echo_info "Installed the required packages"
    echo ""
    install_golang_kernel_libraries
    check_golang_kernel_libraries_installation

}
main "$@"

