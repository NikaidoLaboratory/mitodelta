package SpliceBreak;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;


public class CompareMT {

    public static ArrayList<List<String>> readFile(String path) throws IOException{
    	try (BufferedReader br = new BufferedReader(new FileReader(path))) {

    		ArrayList<List<String>> result = new ArrayList<>();
            String line;
            while ((line = br.readLine()) != null) {
                String[] values = line.split("[\\s,]+");
                
                List<String> list = Arrays.asList(values); 
                
                List<String> l = new ArrayList<>(list);

                result.add(l);
            }

            /**
             *System.out.println(result.get(1));
             */
            return result;
        }
    	
    }
    

    public static void main(String[] args) throws IOException {
    	/**
         *System.out.println("Argument count: " + args.length);
         */
        for (int i = 0; i < args.length; i++) {
            /**
             *System.out.println("Argument " + i + ": " + args[i]);
             */
        }
        Path path1 = Paths.get(args[0]);
        /**
         *System.out.printf("%-25s : %s%n", "path.getParent()", path1.getParent());
         */
        
        String path = path1.getParent().toString();

    	ArrayList<List<String>> orginalFile = readFile(args[0]);
        
        /**
         *System.out.println("here is mitomap");
         */
        ArrayList<List<String>> compareFile = readFile(args[1]);
        
        /**
         * 
         * make the header with Gene name
         *System.out.println(compareFile.size());
         */
        for(int i = 1; i < compareFile.size(); i ++) {
        	
        	String col = "IMPACT_" + compareFile.get(i).get(0);
        	List<String> header = orginalFile.get(0);
            header.add(col);
        }
        /**
         *System.out.println(orginalFile.get(0));
         *
         *
         * compare the 3 and 4/ 1 and 2
         * give define to impact of mt
         */
        for (int i = 1; i < compareFile.size(); i++) {
        	int mt_start = Integer.valueOf(compareFile.get(i).get(1));
        	int mt_end = Integer.valueOf(compareFile.get(i).get(2));
        	for (int j = 1; j < orginalFile.size(); j++) {
        		int orginal_start = Integer.valueOf(orginalFile.get(j).get(3));
            	int orginal_end = Integer.valueOf(orginalFile.get(j).get(4));
            	List<String> line = orginalFile.get(j);
            	if ((orginal_start <= mt_start && mt_start <= orginal_end) || (orginal_start <= mt_end && mt_end <= orginal_end)||(mt_start <= orginal_start && mt_end >= orginal_end)) {
            		line.add("1");
            	}else {
            		line.add("0");
            	}
        	}
        }
        /**
         *System.out.println(orginalFile.get(1));
         */
        
        
        File f = new File (path + "/new_Impact.txt");
        if (!f.exists()) {
            f.createNewFile();
        }
        FileWriter fw = new FileWriter(f.getAbsoluteFile());
        BufferedWriter bw = new BufferedWriter(fw);

        for(List<String> s : orginalFile) {
            String collect = s.stream().collect(Collectors.joining("\t"));
            bw.write(collect + System.getProperty("line.separator")); 
        }
        bw.close();
        
        
    }
    

	
}
