#!/bin/env bash

#
# created: 28/08/2017
# user: Juan Francisco Cardona Mc'Cormick (jfcmacro)
# purpose: This program initializes the $HOME/.edtcfg file and the
#          directory hierarchy.
#

function getYear {
    local thisYear=$(date +"%Y")
    echo "$thisYear"
}

function getTerm {
    local thisMonth=$(date +"%m")
    local thisTerm=""
    case $thisMonth in
	0[1-6])
	    thisTerm="01"
	    ;;
	0[7-9])
	    thisTerm="02"
	    ;;
	1[0-2])
	    thisTerm="02"
	    ;;
    esac
    echo "$thisTerm"
}

function getVarMsg {
    local myvar
    echo -n $1
    myvar=read
    echo "$myvar"
}

function tolower {
    local mytolower=$(echo $1 | tr '[:upper:]' '[:lower:]')
    echo "$mytolower"
}

function toupper {
    local mytoupper=$(echo $1 | tr '[:lower:]' '[:upper:]')
    echo "$mytoupper"
}

TERM=$(getTerm)
YEAR=$(getYear)
OSNAME=`uname -s`
USERNAME=`id -un`
PREFIX="2447"
# REPOFORMAT="${PREFIX}${USERNAME}"
VERSCTRL="svn"

function createDir {
    if [ ! -d $1 ]
    then
	mkdir $1
    fi
}

function createDirGo {
    if [ ! -d $1 ]
    then
	mkdir $1
    fi
    cd $1
}

function createSvnDirGo {
    if [ ! -d $1 ]
    then
	svn mkdir $1 && cd $1
    else
	cd $1
    fi
}

function linkDir {
    ALTHOME=/cygdrive/c/Users
    if [ -d $HOME/$1 ]
    then
	if  [ ! -h $HOME/$2 ]; then
	    ln -s $HOME/$1  $HOME/$2 2>/dev/null
	fi
    else
	if [ -d $ALTHOME/$3/$1 ]; then
            if [ ! -h $HOME/$2 ]; then
                ln -s $ALTHOME/$3/$1  $HOME/$2 2>/dev/null
            fi
	fi
    fi
}

function usage {
    echo "       $1 -h" >&2
    echo "       $1 -b <url-base> -c <course> -g <group> [-n username] [-p prefix] [-r reponame] -u <url-versctrl> [-v <versctrl> ]" >&2
    exit $2
}

function appendFile {
    echo $1 >> $2
}

longprogname=$0
progname=$(basename $longprogname)

while getopts "b:c:g:hn:p:r:u:v:" opt; do
    case $opt in
	b)
	    URLBASE=$OPTARG
	    ;;
	c)
            COURSE=$(toupper $OPTARG)
            COURSELOWER=$(tolower $OPTARG)
	    ;;
	g)
	    GROUP=$OPTARG
	    ;;
	h)
	    usage $progname 0
	    ;;
        n)
            USERNAME=$OPTARG
            ;;
        p)
            PREFIX=$OPTARG
            ;;
        r)
            REPONAME=$OPTARG
            ;;
        u)
            URLVERSCTRL=$OPTARG
            ;;
	v)
	    VERSCTRL=$OPTARG
	    ;;
	\?)
	    usage $progname 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
	    ;;
    esac
done

if [ -f $HOME/.edtrc ]; then
    echo "$HOME/.edtrc exits" >&2
    exit 1
fi

if [ -z "${URLBASE}" -o -z "${COURSE}" -o -z "${GROUP}" -o -z "${URLVERSCTRL}" ]; then
    echo "URLBASE=$URLBASE"
    echo "COURSE=$COURSE"
    echo "GROUP=$GROUP"
    echo "URLVERSCTRL=$ULRVERSCTRL"
    usage $progname 1
fi

if [ -z "${REPONAME}" ]; then
    REPONAME=$PREFIX$USERNAME
fi

cd $HOME

if [ -f .bash ]; then
    appendFile "export PATH=\$HOME/bin:\$PATH" .bashrc
fi

# Adding JAVA_HOME variables
case $OSNAME in
    CYGWIN*)
        if [ -z "${JAVA_HOME}" ]; then
            JAVA_VERSION=$(ls /cygdrive/c/Program\ Files/Java/ | grep jdk | sed 's/jdk//g' | sort -ru | head -n 1)
            if [ -n "${JAVA_VERSION}" ]; then

	        appendFile "export JAVA_HOME=/cygdrive/c/Program\ Files/Java/jdk$JAVA_VERSION/" .bashrc
	        appendFile "export PATH=\$PATH:\$JAVA_HOME/bin" .bashrc
                #    echo "export CLASSPATH=\$(cygpath -pw .:\$CLASSPATH)">> .bashrc
	        source .bashrc
            else
                JAVA_VERSION=$(ls /cygdrive/c/Program\ Files\ \(x86\)/Java/ | grep jdk | sed 's/jdk//g' | sort -ru | head -n 1)
                if [ - "${JAVA_VERSION}" ]; then
                    appendFile "export JAVA_HOME=/cygdrive/c/Program\ Files\ \(x86\)/Java/jdk$JAVA_VERSION/" .bashrc
	            appendFile "export PATH=\$PATH:\$JAVA_HOME/bin" .bashrc
                    #    echo "export CLASSPATH=\$(cygpath -pw .:\$CLASSPATH)">> .bashrc
	            source .bashrc
                else
                    echo "You don't have Java SDK installed on the usual directories, please install one on them" >&2
                fi
            fi
        fi
        ;;
    *)
        if [ -z "${JAVA_HOME}" ]; then
            if [ -x "$(command -v javac)" ]; then
                TMP=$(command -v javac)
                TMP2=$(dirname $TMP)
                append "export JAVA_HOME=$TMP2" .bashrc
                source .bashrc
            else
                echo "You don't have Java SDK installed on the usual directories, please install one on them" >&2
            fi
        fi
        ;;
esac

# Creating directories
for i in bin lib share include tmp
do
    createDir $i
done

case $OSNAME in
    CYGWIN*)
        linkDir AppData appdata $USERNAME
        linkDir Documents docs $USERNAME
        linkDir Desktop escritorio $USERNAME
        linkDir Downloads descargas $USERNAME
        ;;
    *)
        ;;
esac

cd $HOME

if  [ ! -x "$(command -v ewe)" ]; then
    if [ -x "$(command -v cabal)" ]; then
	echo "Installing ewe last version, it takes few minutes, please wait."
	cabal update
	cabal install ewe --prefix $(cygpath -w $HOME)
	source .bashrc
    else
	echo "Please install Haskell Platform before install ewe" >&2
    fi
fi

appendFile "export MANPATH=\$MANPATH:\$HOME/share/man" $HOME/.bashrc
appendFile "# Adding EDT variables" $HOME/.edtrc
appendFile "export EDT_CURRENT_YEAR=$YEAR" $HOME/.edtrc
appendFile "export EDT_CURRENT_TERM=$TERM" $HOME/.edtrc
appendFile "export EDT_COURSES=$COURSE" $HOME/.edtrc
appendFile "export EDT_CURRENT_COURSE=$COURSE" $HOME/.edtrc
appendFile "export EDT_${COURSE}_URL_BASE=${URLBASE}" $HOME/.edtrc
appendFile "export EDT_${COURSE}_GROUP=${GROUP}" $HOME/.edtrc
appendFile "export EDT_${COURSE}_URL_VERSION_CONTROL=${URLVERSCTRL}" $HOME/.edtrc
appendFile "export EDT_${COURSE}_USERNAME=${USERNAME}" $HOME/.edtrc
appendFile "export EDT_${COURSE}_REPONAME=${REPONAME}" $HOME/.edtrc
appendFile "export EDT_${COURSE}_PREFIX_REPO=${PREFIX}" $HOME/.edtrc
appendFile "export EDT_${COURSE}_VERSION_CONTROL=${VERSCTRL}" $HOME/.edtrc
appendFile ". \$HOME/.edtrc" $HOME/.bashrc

URLINITSCRIPT=$URLBASE/courses/$COURSELOWER/edt_init_script.sh

echo "Getting url $URLINITSCRIPT"

wget $URLINITSCRIPT -O edt_init_script.sh

if [ "$?" -ne 0 ]; then
    echo "edt_init_script.sh cannot be download"
    if [ -f edt_init_script.sh ]; then
        rm -f edt_init_script.sh
    fi
else
    echo "Executing edt_init_script.sh"
    bash $HOME/edt_init_script.sh
fi

createDir $COURSELOWER

# if [ -f $HOME/edt_init_script.sh ]; then
#     rm -f $HOME/edt_init_script.sh
# fi