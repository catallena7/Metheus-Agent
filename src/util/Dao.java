package util;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Dao {
	private static final Logger LOG = LogManager.getLogger(Dao.class);
	private static final HashMap<String, HashMap<String, String>> TABLES = new HashMap<String, HashMap<String, String>>();
	private static final String EventTable = "AGENT_EVENT";

	public boolean isWorking() {
		return true;
	}

	public static void printSQLException(SQLException e) {
		while (e != null) {
			LOG.error("\n----- SQLException -----");
			LOG.error("  SQL State:  " + e.getSQLState());
			LOG.error("  Error Code: " + e.getErrorCode());
			LOG.error("  Message:    " + e.getMessage());
			if (e.getMessage().contains("Table/View")
					|| e.getMessage().contains(" does not exist.")) {
				LOG.fatal(e.getMessage());
				System.exit(1);
			}
			e = e.getNextException();
		}
	}

	public void setColumnInfos(String table) {
		Conf cf = new Conf();
		HashMap<String, String> columnMap = cf.getColumns(table);
		TABLES.put(table, columnMap);
		LOG.trace(table);
	}

	public void checkTables(Connection conn) {
		Statement st = null;
		try {
			Conf cf = new Conf();
			LOG.trace(cf.getConfFile());
			ArrayList<String> tables = cf.getPluginNames();
			for (String table : tables) {
				setColumnInfos(table);
				st = conn.createStatement();
				DatabaseMetaData dbmeta = conn.getMetaData();
				ResultSet rsMeta = dbmeta.getTables(null, null,
						table.toUpperCase(), null);
				ResultSet rsColumns = null;
				HashMap<String, String> columnMap = TABLES.get(table);
				if (rsMeta.next()) {
					LOG.trace(rsMeta.getString("TABLE_NAME")
							+ " table is already exist");
					rsColumns = st.executeQuery("Select TABLENAME,COLUMNNAME "
							+ "FROM sys.systables t, sys.syscolumns "
							+ "WHERE TABLEID = REFERENCEID AND TABLENAME ='"
							+ table.toUpperCase() + "'");
					while (rsColumns.next()) {
						LOG.trace(rsColumns.getString(1) + ":"
								+ rsColumns.getString(2));
					}
					conn.commit();
				} else {
					String SQL = "CREATE TABLE " + table + "(TIME TIMESTAMP ";
					if (columnMap.isEmpty()) {
						LOG.error("Please check your configuration xml, there is no table "
								+ "information about the " + table);
						System.exit(1);
					}
					for (String key : columnMap.keySet()) {
						SQL = SQL + "," + key + " " + columnMap.get(key);
					}
					SQL = SQL + ")";
					LOG.trace(SQL);
					st.execute(SQL);
					conn.commit();
					LOG.trace("Table created");
				}
			}
			DatabaseMetaData dbmeta = conn.getMetaData();
			String table = "AGENT_MGR";
			ResultSet rsMeta = dbmeta.getTables(null, null,
					table.toUpperCase(), null);
			ResultSet rsColumns = null;
			if (rsMeta.next()) {
				LOG.trace(rsMeta.getString("TABLE_NAME")
						+ " table is already exist");
				rsColumns = st.executeQuery("SELECT TABLENAME,COLUMNNAME "
						+ "FROM sys.systables t, sys.syscolumns "
						+ "WHERE TABLEID = REFERENCEID AND TABLENAME ='"
						+ table.toUpperCase() + "'");
				while (rsColumns.next()) {
					LOG.trace(rsColumns.getString(1) + ":"
							+ rsColumns.getString(2));
				}
				conn.commit();
			} else {
				String SQL = "create table "
						+ table
						+ " (ID INTEGER,LAST_UPDATED_TIMESTAMP TIMESTAMP, RESTART_FLAG INT, "
						+ "AGENT_START_TIMESTAMP TIMESTAMP, LAST_SENT_EVENT_ID BIGINT, "
						+ "AGENT_VERSION VARCHAR(10), DISTRO_VERSION VARCHAR(100), KERNEL_VERSION VARCHAR(100), "
						+ "NO_OF_PROCESSOR INT, PROCESSOR_MODEL VARCHAR(100))";
				LOG.trace(SQL);
				st.execute(SQL);
				conn.commit();
				LOG.trace("Agent Management table created");
			}
			rsMeta = dbmeta.getTables(null, null, EventTable, null);
			if (rsMeta.next()) {
				LOG.trace(rsMeta.getString("TABLE_NAME")
						+ " table is already exist");
				rsColumns = st.executeQuery("SELECT TABLENAME,COLUMNNAME "
						+ "FROM sys.systables t, sys.syscolumns "
						+ "WHERE TABLEID = REFERENCEID AND TABLENAME='"
						+ EventTable + "'");
				while (rsColumns.next()) {
					LOG.trace(rsColumns.getString(1) + ":"
							+ rsColumns.getString(2));
				}
				conn.commit();
			} else {
				String SQL = "create table "
						+ EventTable
						+ "(ID BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)"
						+ ",EVENT_CODE VARCHAR(20), SEVERITY VARCHAR(10), MESSAGE VARCHAR(1024), "
						+ "TIME TIMESTAMP,CONSTRAINT PRIMARY_KEY PRIMARY KEY (ID))";
				LOG.trace(SQL);
				st.execute(SQL);
				conn.commit();
				LOG.trace("Agent Event table created");
			}
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (st != null)
					st.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			st = null;
		}
	}

	public void initData(Connection conn, String agentVer) {
		PreparedStatement pst = null;
		try {
			int noOfProcessor = Runtime.getRuntime().availableProcessors();
			String kernelVer = System.getProperty("os.version");
			String sysArch = System.getProperty("os.arch");
			String osName = System.getProperty("os.name");
			String linuxDistroVer = "";
			String processorModel = "";
			if (osName.matches("Linux")) {
				linuxDistroVer = getLinuxDistroVer();
				processorModel = getProcessorModel();
			}
			LOG.trace("cpu=" + noOfProcessor + ",osVersion=" + kernelVer
					+ ",sysArch=" + sysArch + ",distro=" + linuxDistroVer
					+ ",processorModel=" + processorModel);
			conn.setAutoCommit(false);
			String sql = null;
			if (isNew(conn)) {
				sql = "INSERT INTO AGENT_MGR VALUES (0,CURRENT_TIMESTAMP,0,CURRENT_TIMESTAMP,0,'"
						+ agentVer
						+ "','"
						+ linuxDistroVer
						+ "','"
						+ kernelVer
						+ "'," + noOfProcessor + ",'" + processorModel + "')";
			} else {
				sql = "UPDATE AGENT_MGR SET RESTART_FLAG = 0,AGENT_START_TIMESTAMP = CURRENT_TIMESTAMP, "
						+ "AGENT_VERSION='"
						+ agentVer
						+ "',DISTRO_VERSION='"
						+ linuxDistroVer
						+ "',KERNEL_VERSION='"
						+ kernelVer
						+ "',NO_OF_PROCESSOR="
						+ noOfProcessor
						+ ",PROCESSOR_MODEL='"
						+ processorModel
						+ "' WHERE ID = 0";
			}
			LOG.trace(sql);
			pst = conn.prepareStatement(sql);
			pst.executeUpdate();
			conn.commit();
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (pst != null)
					pst.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			pst = null;
		}
	}

	private boolean isNew(Connection conn) {
		ResultSet rs = null;
		Statement s = null;
		boolean isNewFlag = true;
		LOG.trace("Checking");
		try {
			conn.setAutoCommit(false);
			s = conn.createStatement();
			rs = s.executeQuery("SELECT ID FROM AGENT_MGR WHERE id=0");
			while (rs.next()) {
				LOG.trace(rs.getInt(1));
				rs.getInt(1);
				isNewFlag = false;
			}
			conn.commit();
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (rs != null)
					rs.close();
				if (s != null)
					s.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			rs = null;
		}
		LOG.trace(isNewFlag);
		return isNewFlag;
	}

	private String getLinuxDistroVer() {
		String distroVer = "";
		try {
			FileInputStream fis = new FileInputStream("/etc/system-release");
			BufferedReader br = new BufferedReader(new InputStreamReader(fis));
			String line;
			while ((line = br.readLine()) != null) {
				distroVer = line;
				break;
			}
			br.close();
		} catch (IOException e) {
			return "no system-releae file";
		}
		return distroVer;
	}

	private String getProcessorModel() {
		String cpuModel = "";
		try {
			FileInputStream fis = new FileInputStream("/proc/cpuinfo");
			BufferedReader br = new BufferedReader(new InputStreamReader(fis));
			String line;
			while ((line = br.readLine()) != null) {
				if (line.startsWith("model name")) {
					String[] items = line.split(":");
					if (items.length >= 2) {
						cpuModel = items[1];
						break;
					}
				}
			}
			br.close();
		} catch (IOException e) {
			return "no system-releae file";
		}
		return cpuModel;
	}

	public boolean isUpdated(Connection conn) {
		boolean isUpdated = false;
		ResultSet rs = null;
		Statement st = null;
		try {
			st = conn.createStatement();
			rs = st.executeQuery("SELECT RESTART_FLAG FROM AGENT_MGR");
			while (rs.next()) {
				LOG.trace(rs.getInt(1));
				if (rs.getInt(1) == 0) {
					isUpdated = false;
				} else {
					isUpdated = true;
				}
			}
			conn.commit();
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (rs != null)
					rs.close();
				if (st != null)
					st.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			rs = null;
		}
		return isUpdated;
	}

	public void setLastUpdateTime(Connection conn) {
		PreparedStatement pst = null;
		try {
			conn.setAutoCommit(false);
			String sql = "UPDATE AGENT_MGR set LAST_UPDATED_TIMESTAMP = CURRENT_TIMESTAMP WHERE id =0 ";
			LOG.trace(sql);
			pst = conn.prepareStatement(sql);
			pst.executeUpdate();
			conn.commit();
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (pst != null)
					pst.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			pst = null;
		}
	}

	public boolean insertData(Connection conn, String stdOut, String table,
			String PluginPath) {
		PreparedStatement pst = null;
		@SuppressWarnings("unused")
		String line_old = "";
		try {
			conn.setAutoCommit(false);
			HashMap<String, String> columnMap = TABLES.get(table);
			String strSql = "";
			String[] outputLines = stdOut.split("\n");
			StringBuffer sbFront = new StringBuffer("insert into ");
			StringBuffer sbKeyOri = new StringBuffer("");
			StringBuffer sbBack = new StringBuffer(" values");
			int i = 0;
			for (String line : outputLines) {
				StringBuffer sbCurKeyCheck = new StringBuffer("");
				if (line.contains("::") && !line.startsWith("ERROR_CODE")) {
					if (i > 0) {
						sbFront = new StringBuffer("");
						sbBack = new StringBuffer(" ,");
					} else {
						sbFront.append(table);
						sbFront.append(" (TIME");
					}
					sbBack.append(" (CURRENT_TIMESTAMP");
					String[] kvitems = line.split(",,");
					for (String kvitem : kvitems) {
						String[] item = kvitem.split("::");
						line_old = kvitem + item[0];
						if (i == 0) {
							sbFront.append(",");
							sbFront.append(item[0]);
							sbKeyOri.append(item[0]);
							sbKeyOri.append(",");
						} else {
							sbCurKeyCheck.append(item[0]);
							sbCurKeyCheck.append(",");
						}
						if (columnMap.containsKey(item[0])) {
							if (columnMap.get(item[0]).startsWith("varchar")) {
								sbBack.append(",'");
								sbBack.append(item[1]);
								sbBack.append("'");
							} else if (columnMap.get(item[0]).startsWith(
									"float")) {
								sbBack.append(",");
								sbBack.append(item[1]);
							} else {
								LOG.error("You can set dataType only varchar or float at the column. please check your data type about "
										+ item[0]);
								this.insertEvent(conn, "XML002", "ERROR",
										"XML Data Type Error");
								return false;
							}
						} else {
							LOG.error("There is no XML-Conf information about "
									+ item[0] + ". Check your XML.");
							this.insertEvent(conn, "XML001", "ERROR",
									"XML Configuration Error");
							return false;
						}
					}
					if (i == 0 && !line.startsWith("ERROR_CODE")) {
						sbFront.append(") ");
					}
					sbBack.append(") ");
					strSql = strSql + sbFront.append(sbBack).toString();
				}
				if (line.contains("::") && line.startsWith("ERROR_CODE")) {
					HashMap<String, String> errorData = new HashMap<String, String>();
					String[] errKVitems = line.split(",,");
					for (String errKVitem : errKVitems) {
						// Sample:
						// "ERROR_CODE::CPULOAD02,,MESSAGE::no file error,,SEVERITY::FATAL\n"
						String errKVPairs[] = errKVitem.split("::");
						if (errKVPairs.length >= 2) {
							if (errKVPairs[0].matches("ERROR_CODE")
									|| errKVPairs[0].matches("SEVERITY")
									|| errKVPairs[0].matches("MESSAGE")) {
								errorData.put(errKVPairs[0], errKVPairs[1]);
							}
						}
					}
					if (errorData.containsKey("ERROR_CODE")
							&& errorData.containsKey("SEVERITY")
							&& errorData.containsKey("MESSAGE")) {
						LOG.error("event happend1 " + line);
						this.insertEvent(conn, errorData.get("ERROR_CODE"),
								errorData.get("SEVERITY"),
								errorData.get("MESSAGE"));
					} else if (errorData.containsKey("ERROR_CODE")
							&& !errorData.containsKey("SEVERITY")
							&& errorData.containsKey("MESSAGE")) {
						LOG.error("event happend2 " + line);
						this.insertEvent(conn, errorData.get("ERROR_CODE"),
								"NO", errorData.get("MESSAGE"));
					} else {
						LOG.error("Please check Error Message from @"
								+ PluginPath);
						LOG.error("message is " + line);
						this.insertEvent(conn, "NOCODE", "NO", line);
					}
				}
				if (i > 0
						&& !(sbKeyOri.toString().matches(sbCurKeyCheck
								.toString()))) {
					// column name consistency check for multiple stdOut like
					// nfs.pl
					LOG.error("key/value skipped");
					LOG.error("ori_key:" + sbKeyOri);
					LOG.error("cur_key:" + sbCurKeyCheck);
					continue;
				}
				if (line.contains("::") && !line.startsWith("ERROR_CODE")) {
					i++;
				}
			}
			LOG.debug("FinalSQL=" + strSql);
			if (strSql.length() > 5) {
				pst = conn.prepareStatement(strSql);
				pst.executeUpdate();
				conn.commit();
			}
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} catch (ArrayIndexOutOfBoundsException e) {
			LOG.error("ArrayIndexOutOfBoundsException");
			this.insertEvent(conn, "DAO002", "ERROR",
					"ArrayIndexOutOfBoundsException at" + PluginPath);
		} catch (NullPointerException e) {
			e.printStackTrace();
			LOG.error("NullPointerException");
			this.insertEvent(conn, "DAO001", "ERROR", "NullPointExcption");
		} finally {
			try {
				if (pst != null)
					pst.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			pst = null;
		}
		return true;
	}

	public void insertEvent(Connection conn, String eventCode,
			String serverity, String msg) {
		PreparedStatement pst = null;
		@SuppressWarnings("unused")
		String line_old = "";
		try {
			conn.setAutoCommit(false);

			StringBuffer sqlBuf = new StringBuffer("insert into ");
			sqlBuf.append(EventTable);
			sqlBuf.append(" (TIME,EVENT_CODE,SEVERITY,MESSAGE) VALUES (CURRENT_TIMESTAMP,'");
			sqlBuf.append(eventCode);
			sqlBuf.append("','");
			sqlBuf.append(serverity);
			sqlBuf.append("','");
			sqlBuf.append(msg);
			sqlBuf.append("')");
			LOG.trace("FinalSQL=" + sqlBuf.toString());
			pst = conn.prepareStatement(sqlBuf.toString());
			pst.executeUpdate();
			conn.commit();
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (pst != null)
					pst.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			pst = null;
		}
	}

	public void deleteData(Connection conn, Conf cf, long days) {
		Statement st = null;
		try {
			LOG.trace(cf.getConfFile());
			ArrayList<String> tables = cf.getPluginNames();
			for (String table : tables) {
				// Sample: java.sql.TimeStamp
				// pointTS=java.sql.Timestamp.valueOf("2015-10-08 00:00:00");
				long time = 1000 * 60 * 60 * 24 * days;
				LOG.trace(time);
				java.sql.Timestamp basic_timestamp = new java.sql.Timestamp(
						System.currentTimeMillis() - time);
				LOG.trace(basic_timestamp);
				String SQL = "DELETE FROM " + table
						+ " WHERE TIME < TIMESTAMP('" + basic_timestamp + "')";
				LOG.info(SQL);
				st = conn.createStatement();
				st.executeUpdate(SQL);
				conn.commit();
				LOG.trace("data removed");
			}
		} catch (SQLException sqle) {
			printSQLException(sqle);
		} finally {
			try {
				if (st != null)
					st.close();
			} catch (SQLException e) {
				printSQLException(e);
			}
			st = null;
		}
	}
}
