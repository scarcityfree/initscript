#!/bin/bash

version='#0.2 2015-07-26'
# 
### BEGIN INIT INFO
# Provides:   scarcityfree-init.sh
# Required-Start: $local_fs $remote_fs screen-cleanup
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  
# Default-Stop:   
# Short-Description:    scarcityfree.com bukkit gameserver
# Description:    starts/restarts/backs-up/stops bukkit buckproc
### END INIT INFO

buckloc="/home/mine/minerscraft/run/bucket.jar"
buckproc="java"
options='nogui'
usern="mine"
WORLD="survival"
MAXHEAP=1300
MINHEAP=1300
RUNME='java -Xmx${MAXHEAP}M -Xms${MINHEAP}M -jar ${buckloc} ${options}'

mine_user() {
whoami=`whoami`
if [ $whoami = mine ]
  then
    /bin/bash -c "$1"
  else
    echo "wrong user"
fi
}

game_start() {
  if pgrep -u $usern -f $buckloc > /dev/null
  then
    echo "scarcityfree gameserver is running!"
  else
    echo "starting scarcityfree minecraft server..."
    mine_user "cd ~mine/minerscraft/run/ ; screen -S gameserverscreen ./run"
    sleep 4
    if pgrep -u $usern -f $buckproc > /dev/null
    then
      echo 'scarcityfree mineserver running.. :)'
    else
      echo 'Error! could not start gameserver... :('
    fi
  fi
}

game_saveoff() {
  if pgrep -u $usern -f $buckproc > /dev/null
  then
    echo "$buckproc is running... suspending saves"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"say BACKUP STARTING. world will be readonly momentarily...\"\015'"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"save-off\"\015'"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"save-all\"\015'"
    sync
    sleep 10
  else
    echo 'gameserver not running'
  fi
}

game_saveon() {
  if pgrep -u $usern -f $buckproc > /dev/null
  then
    echo "$buckproc is running... re-enabling saves"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"save-on\"\015'"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"say BACKUP ENDED...  you may dig,mine,build, and wreck again.. \"\015'"
  else
    echo 'gameserver not running'
  fi
}

game_stop() {
  if pgrep -u $usern -f $buckproc > /dev/null
  then
    echo "Stopping $buckproc"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"say SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"save-all\"\015'"
    sleep 7
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"say SHUTTING DOWN IN 3 SECONDS. Saving map...\"\015'"
    sleep 1
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"say SHUTTING DOWN IN 2 SECONDS. Saving map...\"\015'"
    sleep 1
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"say SHUTTING DOWN IN 1 SECONDS. Saving map...\"\015'"
    sleep 1
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"stop\"\015'"
    sleep 7
  else
    echo 'gameserver not running'
  fi
  if pgrep -u $usern -f $buckproc > /dev/null
  then
    echo "Error! $buckproc could not be stopped."
  else
    echo 'gameserver is stopped'
  fi
} 

game_backup() {
# intended to back up essential pieces of the game

# # pre things
nameof=`(date +%s)`
#rmme=`(echo ${nameof} | awk {'print $1 - 200'})`
#rmme2month=${rmme:0:4}

mine_user "rm -rf /home/mine/minerscraft/essential_back*.t"
mine_user "rm -rf /home/mine/minerscraft/worldback/survival*a"
mine_user "rsync -at /home/mine/minerscraft/run/survival* /home/mine/minerscraft/worldback/"


# # plugin configs needed
mine_user "rm -rf /home/mine/minerscraft/plugback/*"
mine_user "rsync -at /home/mine/minerscraft/run/plugins/{ClearLag,Clearlag.jar,Homespawn,Homespawn.jar,KitPlugin,KitPlugin.jar,PermissionsEx,PermissionsEx.jar,WorldBorder,WorldBorder.jar,worldedit-bukkit-6.0.jar,WorldGuard,worldguard-6.0.0-beta-05.jar,WorldEdit,dynmap-2.2-alpha-2.jar} /home/mine/minerscraft/plugback/"
mine_user "mkdir /home/mine/minerscraft/plugback/dynmap ; rsync -at /home/mine/minerscraft/run/plugins/dynmap/{configuration.txt,custom-lightings.txt,custom-perspectives.txt,custom-shaders.txt,ids-by-ip.txt,lightings.txt,markers.yml,perspectives.txt,shaders.txt,version.txt,worlds.txt} /home/mine/minerscraft/plugback/dynmap/"

# # server configs needed
mine_user "rm -rf /home/mine/minerscraft/configback/*"
mine_user "rsync -at /home/mine/minerscraft/run/{server-icon.png,banned-players.json,bukkit.yml,commands.yml,bucket.jar,banned-ips.json,back,run,eula.txt,server.properties,usercache.json,whitelist.json,wepif.yml,ops.json,help.yml} /home/mine/minerscraft/configsback/"

# # logs
mine_user "rm -rf /home/mine/minerscraft/logsback/*"
mine_user "rsync -at /home/mine/minerscraft/run/logs/* /home/mine/minerscraft/logsback/"

# # time to zip it all up and stuff...
mine_user "tar -cf /home/mine/minerscraft/essential_back.${nameof,1}.t /home/mine/minerscraft/{configs,plug,world,logs}back"
mine_user "echo \"completed backup essential_back.${nameof,1}.t\" >> /home/mine/minerscraft/run/logs/latest.log"
}

game_cmd() {
  command="$1";
  if pgrep -u $usern -f $buckproc > /dev/null
  then
    pre_log_length=`wc -l "/home/mine/minerscraft/run/logs/latest.log" | awk '{print $1}'`
    echo "$buckproc is running... executing command"
    mine_user "screen -p 0 -S gameserverscreen -X eval 'stuff \"$command\"\015'"
    sleep .1 # assumes that the command will run and print to the log file in less than .1 seconds
    # print output
    tail -n $[`wc -l "/home/mine/minerscraft/run/logs/latest.log" | awk '{print $1}'`-$pre_log_length] "/home/mine/minerscraft/run/logs/latest.log"
  fi
}

#########
##  START STOP CASE
#########
case "$1" in
  start)
    game_start
    ;;
  stop)
    game_stop
    ;;
  restart)
    game_stop
    game_start
    ;;
#  backup)
#    game_backup)
#    ;;
  status)
    if pgrep -u $usern -f $buckproc > /dev/null
    then
      echo "gameserver is running."
    else
      echo "gameserver is not running."
    fi
    ;;
  version)
    echo "$version"
    ;;
  cmd)
    if [ $# -gt 1 ]
    then
      shift
      game_cmd "$*"
    else
      echo "you did someting wrong..."
    fi
    ;;
  lag) 
    game_cmd "lagg tps"
    game_cmd "lagg check"
    ;;
  *)
    echo "sage: $0 {start|stop|#backup|status|restart|cmd}"
    echo 'goodluck :)'
    ;;
esac

exit 0
