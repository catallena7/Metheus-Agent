package main;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.util.HashMap;

import org.apache.commons.exec.CommandLine;
import org.apache.commons.exec.DefaultExecutor;
import org.apache.commons.exec.ExecuteWatchdog;
import org.apache.commons.exec.PumpStreamHandler;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import util.Dao;

public class PluginExecutor {
	private static final Logger LOG= LogManager.getLogger(PluginExecutor.class);
	Conf cf=null;
	private HashMap<String,Integer> pgPathIntv=null;
	private HashMap<String,String> pgPluginTable=null;
	private HashMap<String,Integer> pgPluginTimeout=null;
	private HashMap<String,Integer> pgPluginErrorCnt=new HashMap<String,Integer>(); ;
	private Connection conn;
	private Dao dao;
	public PluginExecutor(Conf cf) {
		this.cf=cf;
	}
	public boolean runPluginCommonExecTimeout(String pluginPath, String table,int timeLimit){
		LOG.info("running="+pluginPath);
		if (pluginPath == null){
			LOG.error("plugin is null:" + pluginPath);
			return false;
		}
		try{
			ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
			DefaultExecutor executor =  new DefaultExecutor();
			ExecuteWatchdog watchdog = new ExecuteWatchdog(timeLimit*1000);
			executor.setWatchdog(watchdog);
			CommandLine cmdLine = CommandLine.parse(pluginPath);
			PumpStreamHandler streamHandler = new PumpStreamHandler(outputStream);
			executor.setStreamHandler(streamHandler);
			if (executor.execute(cmdLine)==0){
				LOG.debug("succeed");
			}else if (watchdog.killedProcess()){
				LOG.error("process timeout");
				dao.insertEvent(conn, "PE003", "ERROR","plugin Timeout @"+pluginPath);
				return false;
			}else{
				LOG.error("execution error");
				return false;
			}
			String stdOut=outputStream.toString();
			if(stdOut.contains("::")){
				LOG.debug("outStream="+stdOut);
				dao.insertData(conn,stdOut,pgPluginTable.get(pluginPath),pluginPath);
			}else if(stdOut.contains("ERROR_CODE")){
				LOG.debug("only error code from"+pluginPath);
				dao.insertData(conn,stdOut,pgPluginTable.get(pluginPath),pluginPath);
			}else{
				LOG.debug("no out from"+pluginPath);
			}
			return true;
		}catch (IOException e){
			LOG.error("IOException",e);
			return false;
		}catch (NullPointerException e){
			LOG.error("NullPointerException", e);
			return false;
		}
	}
	public void runPlugins(Long norTime){
		if (pgPathIntv.isEmpty()){
			LOG.error("please check your configuration xml, there is no plugins information");
			System.exit(0);
		}
		String removeKey=null;
		for (String key : pgPathIntv.keySet()){
			LOG.trace(key+" "+pgPathIntv.get(key));
			if (norTime%(pgPathIntv.get(key)*Agent.INTERVAL)==0){
				LOG.trace("1:"+norTime+" "+pgPathIntv.get(key));
				LOG.trace("time to run"+key);
				if (runPluginCommonExecTimeout(key,pgPluginTable.get(key),pgPluginTimeout.get(key))==false){
					LOG.error("Execution error");
					dao.insertEvent(conn,"PE001", "ERROR","plugin execution error @"+key);
					if(pgPluginErrorCnt.containsKey(key)){
						int cnt=pgPluginErrorCnt.get(key);
						cnt++;
						pgPluginErrorCnt.put(key,cnt);
						if (cnt>3){
							removeKey=key;
						}
					}else{
						pgPluginErrorCnt.put(key,1);
					}
				}else{
					pgPluginErrorCnt.remove(key);
				}
			}else{
				LOG.trace("2:"+norTime+" "+pgPathIntv.get(key));
				LOG.trace("skipped    "+key);
			}
			if (removeKey!=null){
				LOG.info(key+" running error exceed. It was removed.");
				pgPathIntv.remove(key);	
			}
			
		}
	}
	public void setPluginPathInterval(HashMap<String, Integer> plugInfos){
		this.pgPathIntv=plugInfos;
	}
	public void setPluginPathTable(HashMap<String, String> pgPluginTable){
		this.pgPluginTable = pgPluginTable;
	}
	public void setPluginPathTimeout(HashMap<String, Integer> pgPluginTable){
		this.pgPluginTimeout = pgPluginTable;
	}
	public void setDB(Connection conn, Dao dao){
		this.conn =conn;
		this.dao=dao;
	}
}
