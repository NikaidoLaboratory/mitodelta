package SpliceBreak;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class top30 {

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
		// TODO Auto-generated method stub
    	/**
         *System.out.println("Argument count: " + args.length);
         */
        //for (int i = 0; i < args.length; i++) {
            /**
             *System.out.println("Argument " + i + ": " + args[i]);
             */
        //}
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
    	
		//ArrayList<List<String>> orginalFile = readFile("new_Impact.txt");
		
		//ArrayList<List<String>> compareFile = readFile("Updated_Master_Deletion_List-top30-mid-high.txt");
		
		Set<String> mp = new HashSet<String>();
		for(int j = orginalFile.get(0).size()-1; j >= 12; j--) {
			orginalFile.get(0).remove(j);
		}

		
		orginalFile.get(0).add("IMPACT_OLR");
		for(int i = 1; i <orginalFile.size(); i++) {
			//System.out.println(compareFile.get(i));
			mp.add(orginalFile.get(i).get(2));
			String OL = orginalFile.get(i).get(49);
			for(int j = orginalFile.get(i).size()-1; j >= 12; j--) {
				orginalFile.get(i).remove(j);
			}
			orginalFile.get(i).add(OL);
		}
		
		//System.out.println(mp);
		
		String sampleName = orginalFile.get(1).get(0);
		String ref = orginalFile.get(1).get(1);
		String benchmark = orginalFile.get(1).get(7);
		String annotation = orginalFile.get(1).get(9);
		int OL_s= 5721;
		int OL_e= 5798;

		
		for(int i = 1; i <compareFile.size(); i++) {
			
			
			String checkMp = compareFile.get(i).get(0);
			//System.out.println(checkMp);
			if(!mp.contains(checkMp)) {
				String[] mpNumbers = checkMp.split("-");
				//System.out.println(mpNumbers[0]);
				//System.out.println(mpNumbers[1]);
				String prime5 = mpNumbers[0];
				String prime3 = mpNumbers[1];
				int deletionSize = Integer.parseInt(prime3)-Integer.parseInt(prime5)-1;
				List<String> newline = new ArrayList<>();
				newline.add(sampleName);
				newline.add(ref);
				newline.add(checkMp);
				newline.add(prime5);
				newline.add(prime3);
				newline.add(String.valueOf(deletionSize));
				newline.add("0");
				newline.add(benchmark);
				newline.add("0");
				newline.add(annotation);
				newline.add("0");
				newline.add("0");
				if ((Integer.parseInt(prime5) <= OL_s && OL_s <= Integer.parseInt(prime3)) || (Integer.parseInt(prime5) <= OL_e && OL_e <= Integer.parseInt(prime3))||(OL_s <= Integer.parseInt(prime5) && OL_e >= Integer.parseInt(prime3))) {
					newline.add("1");
            	}else {
            		newline.add("0");
            	}
				
				orginalFile.add(newline);
			}
			
		}
		
        //File f = new File ("new_result.txt");
        File f = new File (path + "/result.txt");
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
