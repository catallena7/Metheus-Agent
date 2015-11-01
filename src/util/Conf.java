package util;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

public class Conf {
	private static final Logger LOG = LogManager.getLogger(Conf.class);
	private static String fileName = null;

	@SuppressWarnings("static-access")
	public void setConfFile(String fileName) {
		File f = new File(fileName);
		if (!f.isFile()) {
			LOG.error("There is no configulation xml file");
			System.exit(1);
		}
		this.fileName = fileName;
	}

	@SuppressWarnings("static-access")
	public String getConfFile() {
		return this.fileName;
	}

	public int getSinglefValue(String key) {
		try {
			LOG.trace(fileName);
			InputSource is = new InputSource(new FileReader(fileName));
			Document document = DocumentBuilderFactory.newInstance()
					.newDocumentBuilder().parse(is);
			XPath xpath = XPathFactory.newInstance().newXPath();
			String expression = "/agent/" + key;
			int value = Integer.parseInt((xpath.compile(expression)
					.evaluate(document)));
			LOG.trace(key + ":" + value);
			return value;
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (XPathExpressionException e) {
			e.printStackTrace();
		}
		LOG.fatal("No config value about " + key);
		return 0;
	}

	public ArrayList<String> getPluginNames() {
		ArrayList<String> tableList = new ArrayList<String>();
		try {
			LOG.trace(fileName);
			InputSource is = new InputSource(new FileReader(fileName));
			Document document = DocumentBuilderFactory.newInstance()
					.newDocumentBuilder().parse(is);
			XPath xpath = XPathFactory.newInstance().newXPath();
			String expression = "//plugins/plugin";
			NodeList cols = (NodeList) xpath.compile(expression).evaluate(
					document, XPathConstants.NODESET);
			for (int idx = 0; idx < cols.getLength(); idx++) {
				String tableName = cols.item(idx).getAttributes().item(0)
						.getTextContent();
				tableList.add(tableName);
				LOG.trace("plugin:" + tableName);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (XPathExpressionException e) {
			e.printStackTrace();
		}
		return tableList;
	}

	public HashMap<String, String> getColumns(String tableName) {
		HashMap<String, String> columnMap = new HashMap<String, String>();
		try {
			// LOG.trace(fileName+" "+tableName);
			InputSource is = new InputSource(new FileReader(fileName));
			Document document = DocumentBuilderFactory.newInstance()
					.newDocumentBuilder().parse(is);
			XPath xpath = XPathFactory.newInstance().newXPath();
			String expression = "//plugins/plugin[@name='" + tableName
					+ "']/columns/column";
			NodeList cols = (NodeList) xpath.compile(expression).evaluate(
					document, XPathConstants.NODESET);
			for (int idx = 0; idx < cols.getLength(); idx++) {
				String colName = cols.item(idx).getAttributes().item(0)
						.getTextContent();
				expression = "//plugins/plugin[@name='" + tableName
						+ "']/columns/column/type[@name='" + colName + "']";
				String colType = xpath.compile(expression).evaluate(document);
				columnMap.put(colName, colType);
				LOG.trace("column:" + colName + "," + colType);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (XPathExpressionException e) {
			e.printStackTrace();
		}
		return columnMap;
	}

	public HashMap<String, Integer> getPluginInterval() {
		HashMap<String, Integer> pgPthIntv = new HashMap<String, Integer>();
		try {
			LOG.trace(fileName);
			InputSource is = new InputSource(new FileReader(fileName));
			Document document = DocumentBuilderFactory.newInstance()
					.newDocumentBuilder().parse(is);
			XPath xpath = XPathFactory.newInstance().newXPath();
			String expression = "//plugins/plugin";
			NodeList cols = (NodeList) xpath.compile(expression).evaluate(
					document, XPathConstants.NODESET);
			for (int idx = 0; idx < cols.getLength(); idx++) {
				String pluginName = cols.item(idx).getAttributes().item(0)
						.getTextContent();
				expression = "//plugins/plugin[@name='" + pluginName
						+ "']/path";
				String path = xpath.compile(expression).evaluate(document);
				expression = "//plugins/plugin[@name='" + pluginName
						+ "']/interval_sec";
				int interval = Integer.parseInt((xpath.compile(expression)
						.evaluate(document)));
				pgPthIntv.put(path, interval);
				LOG.trace("plugin:" + path + ":" + interval);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (XPathExpressionException e) {
			e.printStackTrace();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}
		return pgPthIntv;
	}

	public HashMap<String, String> getPluginTables() {
		HashMap<String, String> pluginTables = new HashMap<String, String>();
		try {
			LOG.trace(fileName);
			InputSource is = new InputSource(new FileReader(fileName));
			Document document = DocumentBuilderFactory.newInstance()
					.newDocumentBuilder().parse(is);
			XPath xpath = XPathFactory.newInstance().newXPath();
			String expression = "//plugins/plugin";
			NodeList cols = (NodeList) xpath.compile(expression).evaluate(
					document, XPathConstants.NODESET);
			for (int idx = 0; idx < cols.getLength(); idx++) {
				String table = cols.item(idx).getAttributes().item(0)
						.getTextContent();
				expression = "//plugins/plugin[@name='" + table + "']/path";
				String path = xpath.compile(expression).evaluate(document);
				pluginTables.put(path, table);
				LOG.trace("plugin:" + path + ":" + table);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (XPathExpressionException e) {
			e.printStackTrace();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}
		return pluginTables;
	}

	public HashMap<String, Integer> getPluginTimeout() {
		HashMap<String, Integer> pgPthTout = new HashMap<String, Integer>();
		try {

			InputSource is = new InputSource(new FileReader(fileName));
			Document document = DocumentBuilderFactory.newInstance()
					.newDocumentBuilder().parse(is);
			XPath xpath = XPathFactory.newInstance().newXPath();
			String expression = "//plugins/plugin";
			NodeList cols = (NodeList) xpath.compile(expression).evaluate(
					document, XPathConstants.NODESET);
			for (int idx = 0; idx < cols.getLength(); idx++) {
				String pluginName = cols.item(idx).getAttributes().item(0)
						.getTextContent();
				expression = "//plugins/plugin[@name='" + pluginName
						+ "']/path";
				String path = xpath.compile(expression).evaluate(document);
				expression = "//plugins/plugin[@name='" + pluginName
						+ "']/timeout_sec";
				int interval = Integer.parseInt((xpath.compile(expression)
						.evaluate(document)));
				pgPthTout.put(path, interval);
				LOG.trace("plugin:" + path + ":" + interval);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (XPathExpressionException e) {
			e.printStackTrace();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}
		return pgPthTout;
	}
}