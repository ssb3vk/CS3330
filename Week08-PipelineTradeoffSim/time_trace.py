#!/usr/bin/python3
import argparse
import csv

"""
Simulate based on the instruction trace read from 'fh'.

This is meant to represent a simple five-stage pipeline with:
* load/use hazards
* branch delay penalty for non-taken branches

The stalls introduced by each of these are assumed to be independent. (For example,
if a load is a cache miss followed by a load/use hazard, this assumes that both the
full cache miss penalty plus the full load/use hazard penalty must be taken,
even though maybe a processor could perhaps use clever forwarding to avoid the extra cycle
of load/use hazard penalty.)

Takes arguments:
    args: contains the command-line arguments passed to this program. If you want to
          support additional command line arguments, add new `add_argument` calls
          in main()
    fh: the file handle for the trace CSV file

Returns a dictionary containing:
    branch_delay: estimated delay from branch mispredictions
    load_use_delay: estimated delay from load_use hazards
    delay: total delay of all types
    cycles: total simualted cycles
    instructions: total instructions processed
"""
def count_time_in(args, fh):
    csv_reader = csv.DictReader(fh)

    # last instruction, for detecting load/use hazards
    last_instruction = None

    # number instructions processed
    num_instructions = 0

    # total cycles accounted to load/use hazards
    load_use_delay = 0

    # total cycles account to branch misprediction penalties
    branch_delay = 0

    #the following line is needed for part 6
    branch_dict = {}

    for instruction in csv_reader:
        
        #the following two lines are needed for part 6
        if instruction['is_conditional_branch'] == 'Y' and not(instruction['orig_pc'] in branch_dict.keys()): 
              branch_dict[instruction['orig_pc']] = 'Y'
     
        if last_instruction != None:
            forward_from_last = (
                last_instruction['dst'] != '' and
                last_instruction['dst'] in (instruction['srcA'], instruction['srcB'])
            )

            # an addition needed for part 5
            #if forward_from_last == True: 
            #    load_use_delay += 1

            if args.load_use_hazard and forward_from_last and last_instruction['is_memory_read'] == 'Y':
                load_use_delay += 1
        
        # the line needs to be modified to "make" part 3
        #this was commented out for part 6        
        #if instruction['is_conditional_branch'] == 'Y' and instruction['branch_taken'] == 'N':
        #    branch_delay += args.branch_delay

        #the following three lines of code are needed for part 6
        if instruction['is_conditional_branch'] == 'Y' and instruction['branch_taken'] != branch_dict[instruction['orig_pc']]: 
             branch_delay += args.branch_delay

        branch_dict[instruction['orig_pc']] = instruction['branch_taken']

        last_instruction = instruction
        num_instructions += 1

    return {
        'load_use_delay': load_use_delay,
        'branch_delay': branch_delay,
        'delay': load_use_delay + branch_delay,
        'cycles': num_instructions + load_use_delay + branch_delay,
        'instructions': num_instructions,
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=argparse.FileType('r'), metavar='INPUT-FILE')
    parser.add_argument('--enable-load-use-hazard', action='store_true', dest='load_use_hazard',
        help='enable simulated load/use hazard (default)',
        default=True,
    )
    parser.add_argument('--disable-load-use-hazard', action='store_false', dest='load_use_hazard',
        help='disable simulated load/use hazard'
    )
    parser.add_argument('--branch-delay', default=2, type=int, help='branch delay in cycles')
    args = parser.parse_args()
    result = count_time_in(args, args.input)
    print("Total cycles", result['cycles'])
    print("Total instructions", result['instructions'])
    print("Total branch delay", result['branch_delay'])
    print("Total load/use hazard delay", result['load_use_delay'])
    print("Total delay", result['delay'])

if __name__ == '__main__':
    main()
