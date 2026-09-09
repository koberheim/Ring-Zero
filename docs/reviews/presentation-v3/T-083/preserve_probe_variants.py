"""Reconstruct diagnostic fixtures from the recorded edit trail, not launch snapshots."""
from pathlib import Path

root = Path(__file__).resolve().parent
project = root.parents[3]
bounded = (project / 'tests/performance/measure_t083_collapse.gd').read_text()
old_loop = '''\t\tfor slot in 5:
\t\t\t# Actual ring power supports three Flak per sector and the real armor
\t\t\t# cap supports two. This bounded fixture makes no maximum-load claim.
\t\t\tvar placed: Dictionary = sim.place_weapon(12,wedge,slot,&"flak") if slot < 3 else sim.place_armor(12,wedge,slot)'''
new_loop = '''\t\tfor slot in int(sim.state.rings[12].wedges[wedge].slot_count):
\t\t\t# Respect real ring power and the two-armor-per-wedge cap. Repair
\t\t\t# nodes are valid nonpowered remaining hardware on healthy sectors.
\t\t\tvar placed: Dictionary = sim.place_weapon(12,wedge,slot,&"flak") if slot < 3 else (sim.place_armor(12,wedge,slot) if slot < 5 else sim.place_repair_node(12,wedge,slot))'''
assert old_loop in bounded
dense = bounded.replace(old_loop, new_loop)
dense = dense.replace('"damage_per_second":6.0 if index == 0 else 0.0,"speed_ring_widths_per_second":1.0 if index == 0 else 0.00001}', '"damage_per_second":1e7 if index == 0 else 0.0,"speed_ring_widths_per_second":1.0 if index == 0 else 0.00001,"stun_remaining":1.1 if index == 0 else 0.0}')
dense = dense.replace('admission.get("hardware",0) == 25,"All actual loaded hardware retained"', 'admission.get("hardware",0) == 5*int(sim.state.rings[12].wedges[8].slot_count),"All real dense hardware retained"')
assert 'stun_remaining' in dense and 'place_repair_node' in dense
(root / 'probe-variants').mkdir(exist_ok=True)
(root / 'probe-variants' / 'load04-reconstructed.gd.txt').write_text('# RECONSTRUCTED from recorded edit trail, not an original launch-time source snapshot.\n' + dense)
(root / 'probe-variants' / 'load05-frozen.gd.txt').write_text(bounded)
