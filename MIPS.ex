defmodule Emulator do

    def run(prgm) do
        {code,data} = Program.load(prgm)
        out = Out.new()
        reg = Registers.new()
        run(0,code,reg,data,out)
    end

    def run(pc,code,reg,mem,out) do
        next = Program.read_instruction(code,pc)
        case next do
            :halt ->
                Out.close(out)
            {:out,rs} ->
                pc = pc + 4
                s = Registers.read(reg,rs)
                out = Out.put(out, s)
                run(pc,code,reg,mem,out)
            {:label, atom} ->
                pc = pc+4
                run(pc,code,reg,mem,out)
            {:add, rd, rs, rt} ->
                pc = pc + 4
                s = Registers.read(reg,rs)
                t = Registers.read(reg,rt)
                reg = Registers.write(reg,rd, s + t)
                run(pc,code,reg,mem,out)
            {:addi,rd,rs,imm} ->
                pc = pc + 4
                s = Registers.read(reg,rs)
                reg = Registers.write(reg,rd,s+imm)
                run(pc,code,reg,mem,out)
            {:sub, rd, rs, rt} ->
                pc = pc + 4
                s = Registers.read(reg,rs)
                t = Registers.read(reg,rt)
                reg = Registers.write(reg,rd, s - t)
                run(pc,code,reg,mem,out)
            {:lw, rd, rt, arg} ->
                pc = pc + 4
                offset = Registers.read(reg,rt)
                reg = Registers.write(reg,rd,Program.read_data(mem,offset,arg))
                run(pc,code,reg,mem,out)
            {:sw, rs, rt, arg} ->
                pc = pc + 4
                offset = Registers.read(reg,rt)
                new_value = Registers.read(reg,rs)
                mem = Program.write_data(mem,offset,arg,rs)
                run(pc,code,reg,mem,out)
            {:bne, rs, rt, label} ->
                s = Registers.read(reg,rs)
                t = Registers.read(reg,rt)
                if s == t do
                    run(pc+4,code,reg,mem,out)
                else 
                    pc = Program.read_data(mem,0,label)
                    run(pc,code,reg,mem,out)
                end
            {:beq, rs, rt, offset} ->
                s = Registers.read(reg, rs)
                t = Registers.read(reg, rt)
                if s == t do
                    pc = pc + (4 * offset)
                    run(pc,code,reg,mem,out)
                else
                    pc = pc + 4
                    run(pc,code,reg,mem,out)
                end
        end
    end
end

defmodule Registers do

    def new() do
        [{0,0}, {1, 0}, {2, 0}, {3, 0}, {4, 0}, {5, 0}, {6, 0}, {7, 0}, {8, 0}, {9, 0}, {10, 0}, {11, 0}, {12, 0}, {13, 0}, {14, 0}, {15, 0}, {16, 0}, {17, 0}, {18, 0}, {19, 0}, {20, 0}, {21, 0}, {22, 0}, {23, 0},
        {24, 0}, {25, 0}, {26, 0}, {27, 0}, {28, 0}, {29, 0}, {30, 0}, {31, 0}]
    end
    
    def read(reg,rs) do
        [{ref,val} | tail] = reg
        cond do
            ref == rs -> val
            true -> read(tail,rs)
        end
    end
    
    def write([],_,_) do [] end
    def write(reg,rd,value) do
        [{ref,reg_val} | tail] = reg;
        cond do
            rd == 0 -> reg
            ref == rd -> [{ref,value} | tail]
            true -> [{ref,reg_val} | write(tail,rd,value)]
        end
    end
end

defmodule Program do

    def load({:prgm, code, data}) do
        {code,data}
    end
    
    def read_instruction(code,0) do [head | tail] = code ; head end
    def read_instruction(code, pc) do
        [head | tail] = code; read_instruction(tail,pc-4)
    end

    def read_data(data,0,atom) do 
        [{label, val} | tail] = data;
        cond do
            label == atom -> val
            true -> read_data(tail,0,atom)
        end
    end
    def read_data(data, offset, atom) do
        [{label,value} | tail] = data
        cond do 
            label != atom -> read_data(tail,offset,atom)
            true ->[head | rest] = tail; {first,second} = head; read_data(tail,offset-4,first)
        end
    end

    def write_data(data,0,atom,new_value) do 
        [{label, val} | tail] = data;
        cond do
            label == atom -> [{atom,new_value} | tail]
            true -> [{label, val} | write_data(tail,0,atom,new_value)]
        end
    end
    def write_data(data,offset,atom,new_value) do
        [{label,value} | tail] = data
        cond do 
            label != atom -> write_data(tail,offset,atom,value)
            true ->[head | rest] = tail; {first,second} = head; [{label,value} | write_data(tail,offset-4,first,new_value)]
        end
    end
end

defmodule Out do

    def new() do [] end

    def close([]) do IO.write("Program execution completed sucsessfully \n") end
    def close(out) do
        [head | tail] = out
        close(tail)
        IO.write("#{head} \n")
    end

    def put([], s) do [s] end
    def put(out, s)do [s | out] end
end